using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace SmartStepsServer.Migrations
{
    /// <inheritdoc />
    public partial class Update : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Island",
                columns: table => new
                {
                    IslandId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    ImageUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    OrderIndex = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Island", x => x.IslandId);
                    table.CheckConstraint("CK_Island_Status", "[Status] IN ('Active', 'Hidden')");
                });

            migrationBuilder.CreateTable(
                name: "Skill",
                columns: table => new
                {
                    SkillId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Skill", x => x.SkillId);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    UserId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FullName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Email = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: false),
                    Password = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: false),
                    Role = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    ParentId = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.UserId);
                    table.CheckConstraint("CK_Users_Role", "[Role] IN ('Child', 'Parent', 'Admin', 'ContentCreator')");
                    table.ForeignKey(
                        name: "FK_Users_Users_ParentId",
                        column: x => x.ParentId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateTable(
                name: "Situation",
                columns: table => new
                {
                    SituationId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    IslandId = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Intro = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    OrderIndex = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Situation", x => x.SituationId);
                    table.CheckConstraint("CK_Situation_Status", "[Status] IN ('Draft', 'Pending', 'Approved', 'Rejected', 'Published', 'Hidden')");
                    table.ForeignKey(
                        name: "FK_Situation_Island_IslandId",
                        column: x => x.IslandId,
                        principalTable: "Island",
                        principalColumn: "IslandId");
                });

            migrationBuilder.CreateTable(
                name: "Flashcard",
                columns: table => new
                {
                    FlashcardId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    SituationId = table.Column<int>(type: "int", nullable: false),
                    Question = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    OptionA = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    OptionB = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    QuestionVoiceUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    OptionAVoiceUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    OptionBVoiceUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    CorrectAnswer = table.Column<string>(type: "char(1)", fixedLength: true, maxLength: 1, nullable: false),
                    CorrectFeedback = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    WrongFeedback = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Flashcard", x => x.FlashcardId);
                    table.CheckConstraint("CK_Flashcard_CorrectAnswer", "[CorrectAnswer] IN ('A', 'B')");
                    table.ForeignKey(
                        name: "FK_Flashcard_Situation_SituationId",
                        column: x => x.SituationId,
                        principalTable: "Situation",
                        principalColumn: "SituationId");
                });

            migrationBuilder.CreateTable(
                name: "ParentReviewQuestion",
                columns: table => new
                {
                    QuestionId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    SkillId = table.Column<int>(type: "int", nullable: false),
                    SituationId = table.Column<int>(type: "int", nullable: false),
                    QuestionText = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SuggestedActivity = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ParentReviewQuestion", x => x.QuestionId);
                    table.ForeignKey(
                        name: "FK_ParentReviewQuestion_Situation_SituationId",
                        column: x => x.SituationId,
                        principalTable: "Situation",
                        principalColumn: "SituationId");
                    table.ForeignKey(
                        name: "FK_ParentReviewQuestion_Skill_SkillId",
                        column: x => x.SkillId,
                        principalTable: "Skill",
                        principalColumn: "SkillId");
                });

            migrationBuilder.CreateTable(
                name: "SituationSkill",
                columns: table => new
                {
                    SituationId = table.Column<int>(type: "int", nullable: false),
                    SkillId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SituationSkill", x => new { x.SituationId, x.SkillId });
                    table.ForeignKey(
                        name: "FK_SituationSkill_Situation_SituationId",
                        column: x => x.SituationId,
                        principalTable: "Situation",
                        principalColumn: "SituationId");
                    table.ForeignKey(
                        name: "FK_SituationSkill_Skill_SkillId",
                        column: x => x.SkillId,
                        principalTable: "Skill",
                        principalColumn: "SkillId");
                });

            migrationBuilder.CreateTable(
                name: "SituationStep",
                columns: table => new
                {
                    StepId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    SituationId = table.Column<int>(type: "int", nullable: false),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    MediaUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: true),
                    StepType = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    OrderIndex = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SituationStep", x => x.StepId);
                    table.CheckConstraint("CK_SituationStep_StepType", "[StepType] IN ('Intro', 'Story', 'Flashcard', 'Result')");
                    table.ForeignKey(
                        name: "FK_SituationStep_Situation_SituationId",
                        column: x => x.SituationId,
                        principalTable: "Situation",
                        principalColumn: "SituationId");
                });

            migrationBuilder.CreateTable(
                name: "UserAnswer",
                columns: table => new
                {
                    AnswerId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    FlashcardId = table.Column<int>(type: "int", nullable: false),
                    SelectedAnswer = table.Column<string>(type: "char(1)", fixedLength: true, maxLength: 1, nullable: false),
                    IsCorrect = table.Column<bool>(type: "bit", nullable: false),
                    AttemptCount = table.Column<int>(type: "int", nullable: false),
                    AnsweredAt = table.Column<DateTime>(type: "datetime", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserAnswer", x => x.AnswerId);
                    table.CheckConstraint("CK_UserAnswer_AttemptCount", "[AttemptCount] >= 1");
                    table.CheckConstraint("CK_UserAnswer_SelectedAnswer", "[SelectedAnswer] IN ('A', 'B')");
                    table.ForeignKey(
                        name: "FK_UserAnswer_Flashcard_FlashcardId",
                        column: x => x.FlashcardId,
                        principalTable: "Flashcard",
                        principalColumn: "FlashcardId");
                    table.ForeignKey(
                        name: "FK_UserAnswer_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.CreateTable(
                name: "UserProgress",
                columns: table => new
                {
                    ProgressId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    IslandId = table.Column<int>(type: "int", nullable: false),
                    SituationId = table.Column<int>(type: "int", nullable: false),
                    CurrentStep = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<string>(type: "varchar(30)", maxLength: 30, nullable: false),
                    LastAccessedAt = table.Column<DateTime>(type: "datetime", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "GETDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserProgress", x => x.ProgressId);
                    table.CheckConstraint("CK_UserProgress_Status", "[Status] IN ('InProgress', 'Completed')");
                    table.ForeignKey(
                        name: "FK_UserProgress_Island_IslandId",
                        column: x => x.IslandId,
                        principalTable: "Island",
                        principalColumn: "IslandId");
                    table.ForeignKey(
                        name: "FK_UserProgress_SituationStep_CurrentStep",
                        column: x => x.CurrentStep,
                        principalTable: "SituationStep",
                        principalColumn: "StepId");
                    table.ForeignKey(
                        name: "FK_UserProgress_Situation_SituationId",
                        column: x => x.SituationId,
                        principalTable: "Situation",
                        principalColumn: "SituationId");
                    table.ForeignKey(
                        name: "FK_UserProgress_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId");
                });

            migrationBuilder.InsertData(
                table: "Island",
                columns: new[] { "IslandId", "CreatedAt", "Description", "ImageUrl", "Name", "OrderIndex", "Status", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Level 1 - An toàn cá nhân", null, "Personal Safety", 1, "Active", null },
                    { 2, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Level 2 - An toàn môi trường", null, "Environmental Safety", 2, "Active", null },
                    { 3, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Level 3 - An toàn xã hội", null, "Social Safety", 3, "Active", null }
                });

            migrationBuilder.InsertData(
                table: "Skill",
                columns: new[] { "SkillId", "CreatedAt", "Description", "Name", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Nhận biết đồ vật nguy hiểm có nguy cơ gây hóc/nuốt phải; biết phân biệt đồ ăn được và không ăn được.", "An toàn dị vật", null },
                    { 2, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Nhận biết mối nguy hiểm từ dòng điện; không tự ý chạm hoặc nhét vật lạ vào ổ cắm.", "An toàn điện", null },
                    { 3, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Nhận biết mối nguy hại từ thiết bị gia dụng có chứa nước sôi/nhiệt độ cao; kiềm chế hành vi tò mò nguy hiểm.", "An toàn nước nóng", null },
                    { 4, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Biết chờ đèn xanh trước khi qua đường.", "An toàn giao thông", null },
                    { 5, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Biết tìm người giúp đỡ khi bị lạc.", "Xử lý khi bị lạc", null },
                    { 6, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Biết tìm người lớn giúp đỡ khi gặp nguy hiểm gần hồ nước hoặc hồ bơi.", "An toàn hồ nước", null },
                    { 7, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Cảnh giác với người lạ giả danh người quen.", "Cảnh giác người lạ", null },
                    { 8, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Từ chối áp lực bạn bè và không làm việc nguy hiểm để chứng tỏ bản thân.", "Từ chối áp lực bạn bè", null },
                    { 9, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Vượt qua lòng tham, trung thực trả lại của rơi.", "Trung thực", null }
                });

            migrationBuilder.InsertData(
                table: "Situation",
                columns: new[] { "SituationId", "CreatedAt", "Intro", "IslandId", "OrderIndex", "Status", "Title", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bé học cách nhận biết vật nhỏ lạ, không bỏ vào miệng và đưa cho người lớn.", 1, 1, "Published", "Bài 1: Vật tròn lấp lánh", null },
                    { 2, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bé học cách tránh xa ổ cắm điện và không chọc vật kim loại vào ổ điện.", 1, 2, "Published", "Bài 2: Bàn tay kỳ diệu và các cái lỗ", null },
                    { 3, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bé học cách tránh xa bình nước nóng và không tự ý nghịch nút bấm.", 1, 3, "Published", "Bài 3: Cơn nghiện ấn nút", null },
                    { 4, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bé học cách chờ đèn xanh, nắm tay người lớn và nhìn hai bên trước khi qua đường.", 2, 1, "Published", "Bài 1: Qua đường an toàn", null },
                    { 5, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bé học cách đứng yên và tìm nhân viên giúp đỡ khi không thấy ba mẹ.", 2, 2, "Published", "Bài 2: Bị lạc trong siêu thị", null },
                    { 6, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bé học cách tránh xa mép nước và tìm người lớn khi đồ chơi rơi xuống hồ.", 2, 3, "Published", "Bài 3: Hồ nước / hồ bơi", null },
                    { 7, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bé học cách cảnh giác với người lạ dù người đó biết tên mình hoặc nói quen ba mẹ.", 3, 1, "Published", "Bài 1: Người lạ biết tên bé", null },
                    { 8, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bé học cách nói không với lời thách đố nguy hiểm và tìm người lớn giúp đỡ.", 3, 2, "Published", "Bài 2: Lời thách đố của bạn bè", null },
                    { 9, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bé học cách trung thực trả lại của rơi dù không có ai nhìn thấy.", 3, 3, "Published", "Bài 3: Chiếc ví bị đánh rơi", null }
                });

            migrationBuilder.InsertData(
                table: "Flashcard",
                columns: new[] { "FlashcardId", "CorrectAnswer", "CorrectFeedback", "CreatedAt", "OptionA", "OptionAVoiceUrl", "OptionB", "OptionBVoiceUrl", "Question", "QuestionVoiceUrl", "SituationId", "UpdatedAt", "WrongFeedback" },
                values: new object[,]
                {
                    { 1, "B", "Bé ngoan lắm! Gặp đồ vật nhỏ lạ rơi trên sàn, hãy đưa ngay cho người lớn nhé!", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Bỏ vào miệng để nếm thử xem sao.", "Lession1/Voices/choice-put-mouth.mp3", "Mang đến đưa cho bố mẹ và nói: \"Con nhặt được cái này ạ!\"", "Lession1/Voices/choice-ask-adult.mp3", "Con định làm gì với vật tròn nhỏ này?", "Lession1/Voices/question.mp3", 1, null, "Nguy hiểm quá! Đồ vật nhỏ không phải đồ ăn, bỏ vào miệng sẽ gây hóc, nghẹt thở và làm đau bụng bé đấy!" },
                    { 2, "B", "Hoan hô bé! Ổ điện không phải là đồ chơi, tránh xa ổ điện là an toàn nhất!", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Chọc thanh sắt vào lỗ xem robot có biến hình không.", null, "Cất thanh sắt vào hộp đồ chơi và tránh xa ổ điện.", null, "Ổ cắm điện nguy hiểm đấy. Con định làm gì?", null, 2, null, "Ổ điện có dòng điện nguy hiểm, chọc đồ kim loại vào có thể bị điện giật rất đau!" },
                    { 3, "B", "Giỏi lắm! Bé đã nhận biết được nước nóng nguy hiểm và không nghịch nút bấm lung tung!", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Nhấn thử cái nút đỏ xem chuyện gì xảy ra.", null, "Tránh xa chiếc bình và đi tìm mẹ.", null, "Bình thủy đang chứa nước rất nóng. Con sẽ làm gì?", null, 3, null, "Nước trong bình cực kỳ nóng, ấn nút có thể làm nước sôi tràn ra gây bỏng tay bé!" },
                    { 4, "B", "Giỏi lắm! Chúng ta luôn chờ đèn xanh để qua đường an toàn!", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Chạy nhanh qua đường.", null, "Đứng lại chờ đèn xanh.", null, "Xe đang chạy rất đông. Con nên làm gì trước khi qua đường?", null, 4, null, "Qua đường khi đèn đỏ rất nguy hiểm! Mình phải chờ đèn xanh và nhìn hai bên." },
                    { 5, "B", "Giỏi lắm! Nhờ người lớn giúp đỡ là cách an toàn nhất.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Chạy đi tìm mẹ khắp nơi.", null, "Đứng yên và tìm nhân viên giúp đỡ.", null, "Nếu bị lạc trong siêu thị, con nên làm gì?", null, 5, null, "Chạy lung tung có thể làm mình lạc xa hơn! Nếu bị lạc, hãy đứng yên và tìm người lớn đáng tin cậy." },
                    { 6, "B", "Giỏi lắm! Khi gặp nơi nguy hiểm, hãy nhờ người lớn giúp đỡ.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Tự chạy lại lấy bóng.", null, "Tìm người lớn giúp đỡ.", null, "Hồ nước có thể rất sâu và trơn. Con nên làm gì bây giờ?", null, 6, null, "Chơi gần hồ nước một mình rất nguy hiểm! Nếu đồ chơi rơi xuống nước, mình phải tìm người lớn giúp đỡ." },
                    { 7, "B", "Quá xuất sắc! Cảnh giác và chạy đi tìm người lớn tin cậy là cách bảo vệ mình thông minh nhất!", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Tin lời cô, bước lên xe ô tô để về với mẹ.", null, "Lùi lại, nói to \"Cháu không đi!\" và chạy vào trường báo cô giáo.", null, "Người lạ nói mẹ nhờ đến đón. Con sẽ xử lý thế nào?", null, 7, null, "Kẻ xấu có thể giả vờ quen biết mẹ con để lừa bắt cóc con đấy!" },
                    { 8, "B", "Tuyệt vời! Biết nói không với trò chơi nguy hiểm chứng tỏ con rất trưởng thành!", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Nhắm mắt trèo rào sang lấy bóng để chứng tỏ mình không nhát gan.", null, "Kiên quyết từ chối bạn và đi tìm người lớn nhờ lấy giúp.", null, "Các bạn đang ép con làm một việc nguy hiểm. Con nên làm gì?", null, 8, null, "Cố chứng tỏ bản thân bằng cách làm việc nguy hiểm không phải là dũng cảm đâu!" },
                    { 9, "B", "Rất đáng tự hào! Sự trung thực của con đáng giá hơn bất kỳ món đồ chơi nào trên đời!", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Lén nhặt chiếc ví giấu vào túi quần để mang về.", null, "Chạy nhanh nhặt lên và lớn tiếng gọi: \"Cô ơi, cô đánh rơi ví này!\"", null, "Nhặt được đồ không phải của mình, mà lại không có ai nhìn thấy. Con sẽ quyết định thế nào?", null, 9, null, "Lấy đồ của người khác sẽ làm họ rất buồn khổ, và chính con cũng cảm thấy tội lỗi." }
                });

            migrationBuilder.InsertData(
                table: "ParentReviewQuestion",
                columns: new[] { "QuestionId", "CreatedAt", "QuestionText", "SituationId", "SkillId", "SuggestedActivity", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Hãy kiểm tra đồ chơi của bé thường xuyên xem có bị lỏng ốc hoặc có những thứ rơi ra ngoài không.", 1, 1, "Trẻ nhỏ khám phá thế giới bằng cách ngậm đồ vật. Hãy giữ các loại pin nút, nam châm hoặc những dị vật xa tầm tay bé.", null },
                    { 2, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Hôm nay, hãy cùng bé đi một vòng quanh nhà và chỉ cho bé các vị trí ổ điện cấm chạm vào.", 2, 2, "Trẻ rất thích khám phá các cấu trúc dạng lỗ. Hãy sử dụng nắp đậy ổ điện an toàn cho toàn bộ ổ cắm tầm thấp.", null },
                    { 3, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Hãy chỉ cho bé phích nước hoặc bình thủy trong nhà và dạy bé từ Nóng kèm hành động rụt tay lại.", 3, 3, "Trẻ không định nghịch nước nóng, trẻ chỉ thích cảm giác được ấn nút hoặc gạt cần. Hãy luôn bật khóa an toàn trẻ em trên các thiết bị này.", null },
                    { 4, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Hôm nay khi ra đường hãy hỏi bé đèn màu nào được đi.", 4, 4, "Bé vẫn hay quên nhìn hai bên trước khi qua đường.", null },
                    { 5, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Hãy hỏi bé: nếu bị lạc trong siêu thị thì con sẽ làm gì?", 5, 5, "Bé vẫn chọn chạy đi tìm mẹ khi bị lạc.", null },
                    { 6, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Hãy hỏi bé: nếu đồ chơi rơi xuống hồ nước thì con sẽ làm gì?", 6, 6, "Bé vẫn có xu hướng tự đến gần mép nước.", null },
                    { 7, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Ba mẹ hãy cùng bé tạo ra một mật khẩu bí mật. Dặn bé chỉ đi theo ai đọc đúng mật khẩu này.", 7, 7, "Bé rất dễ mất cảnh giác khi người lạ ăn mặc đẹp, tỏ ra thân thiện và biết rõ tên bé.", null },
                    { 8, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Đóng vai bạn bè rủ bé làm việc sai, ví dụ lén ăn vụng kẹo trước bữa cơm, xem bé có dám từ chối ba mẹ không.", 8, 8, "Ở độ tuổi này, bé rất sợ bị bạn bè chê cười hoặc tẩy chay, nên dễ nhắm mắt làm liều.", null },
                    { 9, new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Ba mẹ thử cố tình đánh rơi một tờ tiền lẻ trong phòng bé, xem bé sẽ giữ lấy hay đem trả lại cho ba mẹ.", 9, 9, "Bé dễ bị cám dỗ bởi suy nghĩ không ai nhìn thấy thì không sao.", null }
                });

            migrationBuilder.InsertData(
                table: "SituationSkill",
                columns: new[] { "SituationId", "SkillId" },
                values: new object[,]
                {
                    { 1, 1 },
                    { 2, 2 },
                    { 3, 3 },
                    { 4, 4 },
                    { 5, 5 },
                    { 6, 6 },
                    { 7, 7 },
                    { 8, 8 },
                    { 9, 9 }
                });

            migrationBuilder.InsertData(
                table: "SituationStep",
                columns: new[] { "StepId", "Content", "CreatedAt", "MediaUrl", "OrderIndex", "SituationId", "StepType", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "Bối cảnh: Bé đang ngồi chơi một mình trên thảm trong phòng khách. Khi chơi xếp hình với những đồ chơi có hình dáng khác nhau, một viên bi đồ chơi tròn lấp lánh văng ra khỏi mô hình.\nOpening Animation: Bé bò lại gần và nhặt viên bi lên ngắm nghía.\nVoice POV của bé: \"Ồ, viên kẹo tròn này lấp lánh đẹp quá! Không biết vị của nó có ngọt như kẹo mút không nhỉ?\"\nVoice người hướng dẫn: \"Đó không phải là kẹo đâu bé ơi! Con định làm gì với vật tròn nhỏ này?\"", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Lession1/Videos/lesson1-intro.mp4", 1, 1, "Intro", null },
                    { 2, "A. Bỏ vào miệng để nếm thử xem sao. B. Mang đến đưa cho bố mẹ và nói: \"Con nhặt được cái này ạ!\"", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 2, 1, "Flashcard", null },
                    { 3, "Consequence: Bé đưa viên bi vào miệng, ho sặc sụa, hoảng sợ và tay ôm cổ.\nVoice Narrator: \"Nguy hiểm quá! Đồ vật nhỏ không phải đồ ăn, bỏ vào miệng sẽ gây hóc, nghẹt thở và làm đau bụng bé đấy!\"\nVoice hướng dẫn sửa sai: \"Tuyệt đối không bỏ bất cứ vật lạ nào vào miệng con nhé!\"", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Lession1/Videos/lesson1-wrong.mp4", 3, 1, "Story", null },
                    { 4, "Good outcome: Bé nắm chặt viên bi trong lòng bàn tay, chạy đến chỗ mẹ. Mẹ xoa đầu bé khen ngợi và cất viên bi vào tủ cao.\nVoice Narrator: \"Bé ngoan lắm! Gặp đồ vật nhỏ lạ rơi trên sàn, hãy đưa ngay cho người lớn nhé!\"\nReward: Bé không bỏ vật lạ vào miệng! +1 Safety Star.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), "Lession1/Videos/lesson1-correct.mp4", 4, 1, "Result", null },
                    { 5, "Bối cảnh: Bé đang chơi lắp ráp mô hình robot trên sàn nhà. Ngay sát góc tường là một ổ cắm điện tầm thấp nằm đúng tầm tay của bé.\nOpening Animation: Bé cầm một thanh đồ chơi bằng sắt nhỏ, dài. Ánh mắt bé va phải hai cái lỗ nhỏ của ổ cắm điện trên tường.\nVoice POV của bé: \"Ơ, hai cái lỗ trên tường này trông giống như đôi mắt của robot nhỉ? Vừa khít với thanh sắt mình đang cầm luôn!\"\nVoice người hướng dẫn: \"Cẩn thận nhé bé ơi! Đó là ổ cắm điện nguy hiểm đấy. Con định làm gì?\"", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 1, 2, "Intro", null },
                    { 6, "A. Chọc thanh sắt vào lỗ xem robot có biến hình không. B. Cất thanh sắt vào hộp đồ chơi và tránh xa ổ điện.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 2, 2, "Flashcard", null },
                    { 7, "Consequence: Bé đưa thanh sắt chạm vào lỗ ổ điện, màn hình chớp nháy như bị điện giật. Nhân vật giật mình ngã lùi ra sau, tay ôm ngực hoảng sợ.\nVoice Narrator: \"Ôi không! Ổ điện có điện bên trong, chọc đồ kim loại vào sẽ bị điện giật rất đau!\"\nVoice hướng dẫn sửa sai: \"Không bao giờ được dùng tay hoặc đồ vật chọc vào ổ điện con nhé!\"", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 3, 2, "Story", null },
                    { 8, "Good outcome: Bé quay lưng lại với ổ điện, vui vẻ lắp ráp tiếp robot. Bố đi qua dùng nút bịt an toàn gắn chặt vào ổ điện.\nVoice Narrator: \"Hoan hô bé! Ổ điện không phải là đồ chơi, tránh xa ổ điện là an toàn nhất!\"\nReward: Bé biết tránh xa ổ điện! +1 Safety Star.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 4, 2, "Result", null },
                    { 9, "Bối cảnh: Mẹ vừa đun nước xong để pha sữa. Chiếc bình thủy điện được đặt tạm trên một chiếc bàn thấp ở phòng bếp.\nOpening Animation: Chiếc bình thủy điện có cái nút nhấn màu đỏ phát sáng. Bé đi ngang qua và bị thu hút bởi cái nút bấm đó.\nVoice POV của bé: \"Wow, cái nút màu đỏ này phát sáng đẹp quá! Giống như nút bấm phóng tên lửa của phi hành gia vậy, mình phải bấm thử mới được!\"\nVoice người hướng dẫn: \"Dừng lại đã bé ơi! Bình thủy đang chứa nước rất nóng đấy. Con sẽ làm gì?\"", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 1, 3, "Intro", null },
                    { 10, "A. Nhấn thử cái nút đỏ xem chuyện gì xảy ra. B. Tránh xa chiếc bình và đi tìm mẹ.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 2, 3, "Flashcard", null },
                    { 11, "Consequence: Bé ấn mạnh vào nút đỏ, nước sôi phun ra từ vòi trúng vào tay bé. Màn hình hiện hơi nước nóng, tay nhân vật đỏ sưng tấy.\nVoice Narrator: \"Ôi không! Nước trong bình cực kỳ nóng, ấn nút làm nước sôi tràn ra gây bỏng tay bé rồi!\"\nVoice hướng dẫn sửa sai: \"Khi thấy bình nước nóng, con tuyệt đối không được tự ý ấn nút hay nghịch ngợm nhé!\"", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 3, 3, "Story", null },
                    { 12, "Good outcome: Bé rụt tay lại, không bấm nút nữa mà chạy ra phòng khách tìm mẹ. Mẹ dắt tay bé và khen ngợi vì bé biết tự bảo vệ mình.\nVoice Narrator: \"Giỏi lắm! Bé đã nhận biết được nước nóng nguy hiểm và không nghịch nút bấm lung tung!\"\nReward: Bé không nghịch thiết bị nước nóng! +1 Safety Star.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 4, 3, "Result", null },
                    { 13, "Bối cảnh: Bé đi bộ cùng mẹ trên đường về nhà. Phía bên kia đường có tiệm kem rất hấp dẫn. Xe máy chạy qua liên tục và đèn giao thông đang màu đỏ.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 1, 4, "Intro", null },
                    { 14, "A. Chạy nhanh qua đường. B. Đứng lại chờ đèn xanh.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 2, 4, "Flashcard", null },
                    { 15, "Consequence: Bé chạy xuống đường, còi xe kêu liên tục, xe thắng gấp và màn hình rung nhẹ. Narrator: Qua đường khi đèn đỏ rất nguy hiểm.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 3, 4, "Story", null },
                    { 16, "Good outcome: Bé đứng cạnh mẹ, chờ đèn xanh bật rồi hai mẹ con nắm tay qua đường. Reward: Bé biết chờ đèn xanh! +1 Safety Star.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 4, 4, "Result", null },
                    { 17, "Bối cảnh: Bé đang đi siêu thị cùng mẹ. Bé nhìn đồ chơi, quay lại và không thấy mẹ đâu.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 1, 5, "Intro", null },
                    { 18, "A. Chạy đi tìm mẹ khắp nơi. B. Đứng yên và tìm nhân viên giúp đỡ.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 2, 5, "Flashcard", null },
                    { 19, "Consequence: Bé chạy lung tung, càng đi càng xa và nhạc trở nên căng thẳng. Narrator: Chạy lung tung có thể làm mình lạc xa hơn.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 3, 5, "Story", null },
                    { 20, "Good outcome: Bé gặp cô nhân viên, cô phát loa và mẹ tìm thấy bé. Reward: Bé biết xử lý khi bị lạc!", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 4, 5, "Result", null },
                    { 21, "Bối cảnh: Bé đang tự chơi bóng trong công viên gần hồ nước. Quả bóng lăn nhanh về phía hồ rồi rơi xuống nước và nổi gần mép hồ.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 1, 6, "Intro", null },
                    { 22, "A. Tự chạy lại lấy bóng. B. Tìm người lớn giúp đỡ.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 2, 6, "Flashcard", null },
                    { 23, "Consequence: Bé chạy tới mép hồ, cúi xuống lấy bóng. Mặt đất trơn làm bé bị trượt chân, nước bắn lên và bé sợ hãi.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 3, 6, "Story", null },
                    { 24, "Good outcome: Bé chạy tới chú bảo vệ công viên. Chú bảo vệ dùng cây vợt dài lấy bóng lên giúp bé. Reward: Bé biết tránh xa hồ nước sâu! +1 Safety Star.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 4, 6, "Result", null },
                    { 25, "Bối cảnh: Bé đang đứng đợi mẹ ở cổng trường. Một người phụ nữ ăn mặc lịch sự, đi xe ô tô đến, gọi đúng tên bé và tươi cười vẫy gọi.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 1, 7, "Intro", null },
                    { 26, "A. Tin lời cô, bước lên xe ô tô để về với mẹ. B. Lùi lại, nói to \"Cháu không đi!\" và chạy vào trường báo cô giáo.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 2, 7, "Flashcard", null },
                    { 27, "Consequence: Bé vừa bước lên xe, cửa xe đóng sập lại, xe lao vút đi và màn hình nhấp nháy đỏ. Narrator: Rất nguy hiểm! Kẻ xấu có thể giả vờ quen biết mẹ con.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 3, 7, "Story", null },
                    { 28, "Good outcome: Bé lùi lại, chạy thẳng vào cổng trường gọi cô giáo. Người phụ nữ lạ thấy vậy vội vàng bỏ đi. Reward: Bé không mắc mưu kẻ xấu! +1 Brave Star.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 4, 7, "Result", null },
                    { 29, "Bối cảnh: Bé đang chơi đá bóng cùng nhóm bạn. Quả bóng bay qua hàng rào rơi vào sân nhà hàng xóm có nuôi chó dữ.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 1, 8, "Intro", null },
                    { 30, "A. Nhắm mắt trèo rào sang lấy bóng để chứng tỏ mình không nhát gan. B. Kiên quyết từ chối bạn và đi tìm người lớn nhờ lấy giúp.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 2, 8, "Flashcard", null },
                    { 31, "Consequence: Bé leo lên hàng rào, trượt chân té ngã. Con chó chạy ra sủa ầm ĩ và bé khóc vì sợ và đau.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 3, 8, "Story", null },
                    { 32, "Good outcome: Bé lắc đầu kiên quyết nói không, chạy đi gọi chú chủ nhà. Chú mở cửa lấy bóng ra, cả nhóm bạn nể phục bé. Reward: Bé biết nói KHÔNG với nguy hiểm! +1 Shield Star.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 4, 8, "Result", null },
                    { 33, "Bối cảnh: Bé đang đi rửa tay trong khu vui chơi thì thấy một người đi trước làm rơi chiếc ví. Người đó đi khuất, chiếc ví mở hé ra và bên trong có nhiều tờ tiền.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 1, 9, "Intro", null },
                    { 34, "A. Lén nhặt chiếc ví giấu vào túi quần để mang về. B. Chạy nhanh nhặt lên và lớn tiếng gọi: \"Cô ơi, cô đánh rơi ví này!\"", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 2, 9, "Flashcard", null },
                    { 35, "Consequence: Bé cất ví. Lát sau thấy người phụ nữ quay lại khóc lóc nhờ bảo vệ tìm ví vì có giấy tờ nhập viện cho em bé. Bé cúi mặt hối hận.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 3, 9, "Story", null },
                    { 36, "Good outcome: Bé nhặt ví chạy theo đưa tận tay. Người phụ nữ mừng rỡ cảm ơn và tặng bé một sticker Ngôi Sao. Reward: Bé là em bé trung thực! +1 Honesty Star.", new DateTime(2026, 5, 24, 0, 0, 0, 0, DateTimeKind.Unspecified), null, 4, 9, "Result", null }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Flashcard_SituationId",
                table: "Flashcard",
                column: "SituationId");

            migrationBuilder.CreateIndex(
                name: "IX_ParentReviewQuestion_SituationId",
                table: "ParentReviewQuestion",
                column: "SituationId");

            migrationBuilder.CreateIndex(
                name: "IX_ParentReviewQuestion_SkillId",
                table: "ParentReviewQuestion",
                column: "SkillId");

            migrationBuilder.CreateIndex(
                name: "IX_Situation_IslandId",
                table: "Situation",
                column: "IslandId");

            migrationBuilder.CreateIndex(
                name: "IX_SituationSkill_SkillId",
                table: "SituationSkill",
                column: "SkillId");

            migrationBuilder.CreateIndex(
                name: "IX_SituationStep_SituationId",
                table: "SituationStep",
                column: "SituationId");

            migrationBuilder.CreateIndex(
                name: "IX_UserAnswer_FlashcardId",
                table: "UserAnswer",
                column: "FlashcardId");

            migrationBuilder.CreateIndex(
                name: "IX_UserAnswer_UserId",
                table: "UserAnswer",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_UserProgress_CurrentStep",
                table: "UserProgress",
                column: "CurrentStep");

            migrationBuilder.CreateIndex(
                name: "IX_UserProgress_IslandId",
                table: "UserProgress",
                column: "IslandId");

            migrationBuilder.CreateIndex(
                name: "IX_UserProgress_SituationId",
                table: "UserProgress",
                column: "SituationId");

            migrationBuilder.CreateIndex(
                name: "IX_UserProgress_UserId",
                table: "UserProgress",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Email",
                table: "Users",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_ParentId",
                table: "Users",
                column: "ParentId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ParentReviewQuestion");

            migrationBuilder.DropTable(
                name: "SituationSkill");

            migrationBuilder.DropTable(
                name: "UserAnswer");

            migrationBuilder.DropTable(
                name: "UserProgress");

            migrationBuilder.DropTable(
                name: "Skill");

            migrationBuilder.DropTable(
                name: "Flashcard");

            migrationBuilder.DropTable(
                name: "SituationStep");

            migrationBuilder.DropTable(
                name: "Users");

            migrationBuilder.DropTable(
                name: "Situation");

            migrationBuilder.DropTable(
                name: "Island");
        }
    }
}
