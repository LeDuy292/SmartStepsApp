using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;
using SmartStepsServer.Options;

namespace SmartStepsServer.Services;

public sealed class DeepSeekNarrativeService(
    HttpClient httpClient,
    IOptions<DeepSeekOptions> options,
    ILogger<DeepSeekNarrativeService> logger) : IAiNarrativeService
{
    private const string SystemPrompt = """
        Bạn là trợ lý viết báo cáo học tập kỹ năng an toàn cho phụ huynh có trẻ từ 4 đến 10 tuổi.
        Chỉ sử dụng dữ liệu tổng hợp và danh sách bài học đã được hệ thống cung cấp.
        Không chẩn đoán tâm lý hoặc sức khỏe, không gắn nhãn tiêu cực cho trẻ, không tạo hướng dẫn nguy hiểm.
        Không thay đổi kết quả đúng/sai hoặc mức kỹ năng do Rule Engine xác định.
        Chỉ được xếp hạng các situationId có trong candidates; không được tạo ID hoặc bài học mới.
        Lời khuyên phụ huynh chỉ được diễn đạt lại từ approvedParentActivities, không thêm hoạt động chưa kiểm duyệt.
        Giọng văn tiếng Việt tích cực, dễ hiểu, ngắn gọn và dựa trên bằng chứng.
        Trả về duy nhất một JSON object hợp lệ, không markdown, theo đúng cấu trúc:
        {
          "summary": "string",
          "strengths": "string",
          "areasForImprovement": "string",
          "parentAdvice": ["string"],
          "rankedSituationIds": [1]
        }
        """;

    private readonly DeepSeekOptions _options = options.Value;

    public async Task<AiNarrativeResult> GenerateAsync(
        AiNarrativeRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            return Failure("DeepSeek API key is not configured.");
        }

        try
        {
            using var timeoutSource = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            timeoutSource.CancelAfter(TimeSpan.FromSeconds(Math.Clamp(_options.TimeoutSeconds, 5, 120)));

            var payload = new
            {
                model = _options.Model,
                messages = new object[]
                {
                    new { role = "system", content = SystemPrompt },
                    new
                    {
                        role = "user",
                        content = "Hãy phân tích dữ liệu sau và trả về JSON: " +
                            JsonSerializer.Serialize(request),
                    },
                },
                response_format = new { type = "json_object" },
                thinking = new { type = "disabled" },
                temperature = 0.2,
                max_tokens = Math.Clamp(_options.MaxOutputTokens, 400, 4000),
                stream = false,
            };

            using var httpRequest = new HttpRequestMessage(HttpMethod.Post, "chat/completions")
            {
                Content = JsonContent.Create(payload),
            };
            httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _options.ApiKey);

            using var response = await httpClient.SendAsync(httpRequest, timeoutSource.Token);
            var responseBody = await response.Content.ReadAsStringAsync(timeoutSource.Token);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning(
                    "DeepSeek narrative request failed with HTTP {StatusCode}.",
                    (int)response.StatusCode);
                return Failure($"DeepSeek returned HTTP {(int)response.StatusCode}.");
            }

            return ParseResponse(responseBody, request);
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            return Failure("DeepSeek request timed out.");
        }
        catch (Exception exception)
        {
            logger.LogWarning(exception, "DeepSeek narrative generation failed.");
            return Failure("DeepSeek request failed.");
        }
    }

    private AiNarrativeResult ParseResponse(string responseBody, AiNarrativeRequest request)
    {
        using var responseJson = JsonDocument.Parse(responseBody);
        var content = responseJson.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();
        if (string.IsNullOrWhiteSpace(content))
        {
            return Failure("DeepSeek returned empty content.");
        }

        using var narrativeJson = JsonDocument.Parse(content);
        var root = narrativeJson.RootElement;
        var summary = ReadRequiredText(root, "summary", 1400);
        var strengths = ReadRequiredText(root, "strengths", 800);
        var improvements = ReadRequiredText(root, "areasForImprovement", 800);
        if (summary is null || strengths is null || improvements is null)
        {
            return Failure("DeepSeek returned an invalid narrative schema.");
        }

        var approvedCandidateIds = request.Candidates
            .Select(candidate => candidate.SituationId)
            .ToHashSet();
        var rankedIds = ReadIntArray(root, "rankedSituationIds")
            .Where(approvedCandidateIds.Contains)
            .Distinct()
            .Take(approvedCandidateIds.Count)
            .ToList();
        rankedIds.AddRange(approvedCandidateIds.Where(id => !rankedIds.Contains(id)));

        var advice = ReadTextArray(root, "parentAdvice", 3, 600);
        if (request.ApprovedParentActivities.Count == 0)
        {
            advice = [];
        }

        return new AiNarrativeResult
        {
            IsSuccess = true,
            ModelName = $"DeepSeek/{_options.Model}",
            Summary = summary,
            Strengths = strengths,
            AreasForImprovement = improvements,
            ParentAdvice = advice,
            RankedSituationIds = rankedIds,
            RawResponse = content,
        };
    }

    private AiNarrativeResult Failure(string message) => new()
    {
        IsSuccess = false,
        ModelName = $"DeepSeek/{_options.Model}",
        ErrorMessage = message,
    };

    private static string? ReadRequiredText(JsonElement root, string name, int maxLength)
    {
        if (!root.TryGetProperty(name, out var value) || value.ValueKind != JsonValueKind.String)
        {
            return null;
        }

        var text = value.GetString()?.Trim();
        if (string.IsNullOrWhiteSpace(text))
        {
            return null;
        }

        return text.Length <= maxLength ? text : text[..maxLength];
    }

    private static List<string> ReadTextArray(
        JsonElement root,
        string name,
        int maxItems,
        int maxLength)
    {
        if (!root.TryGetProperty(name, out var value) || value.ValueKind != JsonValueKind.Array)
        {
            return [];
        }

        return value.EnumerateArray()
            .Where(item => item.ValueKind == JsonValueKind.String)
            .Select(item => item.GetString()?.Trim())
            .Where(item => !string.IsNullOrWhiteSpace(item))
            .Select(item => item!.Length <= maxLength ? item : item[..maxLength])
            .Distinct()
            .Take(maxItems)
            .ToList();
    }

    private static IEnumerable<int> ReadIntArray(JsonElement root, string name)
    {
        if (!root.TryGetProperty(name, out var value) || value.ValueKind != JsonValueKind.Array)
        {
            return [];
        }

        return value.EnumerateArray()
            .Where(item => item.TryGetInt32(out _))
            .Select(item => item.GetInt32());
    }
}
