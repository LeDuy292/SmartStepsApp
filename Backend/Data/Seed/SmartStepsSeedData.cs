namespace SmartStepsServer.Data.Seed;

internal static class SmartStepsSeedData
{
    public static IReadOnlyList<SmartStepsIslandSeed> Islands { get; } =
    [
        new SmartStepsIslandSeed(
            Name: "Personal Safety",
            Description: "Level 1 - An toàn cá nhân",
            OrderIndex: 1,
            Situations:
            [
                new SmartStepsSituationSeed(
                    Title: "Bài 1: Vật tròn lấp lánh",
                    Topic: "An toàn dị vật",
                    Intro: "Bé học cách nhận biết vật nhỏ lạ, không bỏ vào miệng và đưa cho người lớn.",
                    OrderIndex: 1,
                    SkillName: "An toàn dị vật",
                    SkillDescription: "Nhận biết đồ vật nguy hiểm có nguy cơ gây hóc/nuốt phải; biết phân biệt đồ ăn được và không ăn được.",
                    ParentPractice: "Hãy kiểm tra đồ chơi của bé thường xuyên xem có bị lỏng ốc hoặc có những thứ rơi ra ngoài không.",
                    RiskAlert: "Trẻ nhỏ khám phá thế giới bằng cách ngậm đồ vật. Hãy giữ các loại pin nút, nam châm hoặc những dị vật xa tầm tay bé.",
                    Flashcard: new SmartStepsFlashcardSeed(
                        Question: "Con định làm gì với vật tròn nhỏ này?",
                        OptionA: "Bỏ vào miệng để nếm thử xem sao.",
                        OptionB: "Mang đến đưa cho bố mẹ và nói: \"Con nhặt được cái này ạ!\"",
                        QuestionVoiceUrl: "Lession1/Voices/question.mp3",
                        OptionAVoiceUrl: "Lession1/Voices/choice-put-mouth.mp3",
                        OptionBVoiceUrl: "Lession1/Voices/choice-ask-adult.mp3",
                        CorrectAnswer: "B",
                        CorrectFeedback: "Bé ngoan lắm! Gặp đồ vật nhỏ lạ rơi trên sàn, hãy đưa ngay cho người lớn nhé!",
                        WrongFeedback: "Nguy hiểm quá! Đồ vật nhỏ không phải đồ ăn, bỏ vào miệng sẽ gây hóc, nghẹt thở và làm đau bụng bé đấy!"),
                    Steps:
                    [
                        new SmartStepsSituationStepSeed(
                            StepType: "Intro",
                            OrderIndex: 1,
                            MediaUrl: "Safety_smallitems_intro_cw1tlh.mp4",
                            Content:
                            """
                            Bối cảnh: Bé đang ngồi chơi một mình trên thảm trong phòng khách. Khi chơi xếp hình với những đồ chơi có hình dáng khác nhau, một viên bi đồ chơi tròn lấp lánh văng ra khỏi mô hình.
                            Opening Animation: Bé bò lại gần và nhặt viên bi lên ngắm nghía.
                            Voice POV của bé: "Ồ, viên kẹo tròn này lấp lánh đẹp quá! Không biết vị của nó có ngọt như kẹo mút không nhỉ?"
                            Voice người hướng dẫn: "Đó không phải là kẹo đâu bé ơi! Con định làm gì với vật tròn nhỏ này?"
                            """),
                        new SmartStepsSituationStepSeed(
                            StepType: "Flashcard",
                            OrderIndex: 2,
                            MediaUrl: null,
                            Content: "A. Bỏ vào miệng để nếm thử xem sao. B. Mang đến đưa cho bố mẹ và nói: \"Con nhặt được cái này ạ!\""),
                        new SmartStepsSituationStepSeed(
                            StepType: "Story",
                            OrderIndex: 3,
                            MediaUrl: "Safety_smallitems_wrong_pjogba.mp4",
                            Content:
                            """
                            Consequence: Bé đưa viên bi vào miệng, ho sặc sụa, hoảng sợ và tay ôm cổ.
                            Voice Narrator: "Nguy hiểm quá! Đồ vật nhỏ không phải đồ ăn, bỏ vào miệng sẽ gây hóc, nghẹt thở và làm đau bụng bé đấy!"
                            Voice hướng dẫn sửa sai: "Tuyệt đối không bỏ bất cứ vật lạ nào vào miệng con nhé!"
                            """),
                        new SmartStepsSituationStepSeed(
                            StepType: "Result",
                            OrderIndex: 4,
                            MediaUrl: "Safety_smallitems_correct_u5ubla.mp4",
                            Content:
                            """
                            Good outcome: Bé nắm chặt viên bi trong lòng bàn tay, chạy đến chỗ mẹ. Mẹ xoa đầu bé khen ngợi và cất viên bi vào tủ cao.
                            Voice Narrator: "Bé ngoan lắm! Gặp đồ vật nhỏ lạ rơi trên sàn, hãy đưa ngay cho người lớn nhé!"
                            Reward: Bé không bỏ vật lạ vào miệng! +1 Safety Star.
                            """)
                    ]),
                new SmartStepsSituationSeed(
                    Title: "Bài 2: Bàn tay kỳ diệu và các cái lỗ",
                    Topic: "An toàn điện",
                    Intro: "Bé học cách tránh xa ổ cắm điện và không chọc vật kim loại vào ổ điện.",
                    OrderIndex: 2,
                    SkillName: "An toàn điện",
                    SkillDescription: "Nhận biết mối nguy hiểm từ dòng điện; không tự ý chạm hoặc nhét vật lạ vào ổ cắm.",
                    ParentPractice: "Hôm nay, hãy cùng bé đi một vòng quanh nhà và chỉ cho bé các vị trí ổ điện cấm chạm vào.",
                    RiskAlert: "Trẻ rất thích khám phá các cấu trúc dạng lỗ. Hãy sử dụng nắp đậy ổ điện an toàn cho toàn bộ ổ cắm tầm thấp.",
                    Flashcard: new SmartStepsFlashcardSeed(
                        Question: "Ổ cắm điện nguy hiểm đấy. Con định làm gì?",
                        OptionA: "Chọc thanh sắt vào lỗ xem robot có biến hình không.",
                        OptionB: "Cất thanh sắt vào hộp đồ chơi và tránh xa ổ điện.",
                        CorrectAnswer: "B",
                        CorrectFeedback: "Hoan hô bé! Ổ điện không phải là đồ chơi, tránh xa ổ điện là an toàn nhất!",
                        WrongFeedback: "Ổ điện có dòng điện nguy hiểm, chọc đồ kim loại vào có thể bị điện giật rất đau!"),
                    Steps:
                    [
                        new SmartStepsSituationStepSeed(
                            StepType: "Intro",
                            OrderIndex: 1,
                            MediaUrl: "Safety_stranger_Intro_chanol.mp4",
                            Content:
                            """
                            Bối cảnh: Bé đang chơi lắp ráp mô hình robot trên sàn nhà. Ngay sát góc tường là một ổ cắm điện tầm thấp nằm đúng tầm tay của bé.
                            Opening Animation: Bé cầm một thanh đồ chơi bằng sắt nhỏ, dài. Ánh mắt bé va phải hai cái lỗ nhỏ của ổ cắm điện trên tường.
                            Voice POV của bé: "Ơ, hai cái lỗ trên tường này trông giống như đôi mắt của robot nhỉ? Vừa khít với thanh sắt mình đang cầm luôn!"
                            Voice người hướng dẫn: "Cẩn thận nhé bé ơi! Đó là ổ cắm điện nguy hiểm đấy. Con định làm gì?"
                            """),
                        new SmartStepsSituationStepSeed("Flashcard", 2, null, "A. Chọc thanh sắt vào lỗ xem robot có biến hình không. B. Cất thanh sắt vào hộp đồ chơi và tránh xa ổ điện."),
                        new SmartStepsSituationStepSeed(
                            StepType: "Story",
                            OrderIndex: 3,
                            MediaUrl: "Safety_stranger_wrong_dgsjbj.mp4",
                            Content:
                            """
                            Consequence: Bé đưa thanh sắt chạm vào lỗ ổ điện, màn hình chớp nháy như bị điện giật. Nhân vật giật mình ngã lùi ra sau, tay ôm ngực hoảng sợ.
                            Voice Narrator: "Ôi không! Ổ điện có điện bên trong, chọc đồ kim loại vào sẽ bị điện giật rất đau!"
                            Voice hướng dẫn sửa sai: "Không bao giờ được dùng tay hoặc đồ vật chọc vào ổ điện con nhé!"
                            """),
                        new SmartStepsSituationStepSeed(
                            StepType: "Result",
                            OrderIndex: 4,
                            MediaUrl: "Safety_stranger_correct_rkwehk.mp4",
                            Content:
                            """
                            Good outcome: Bé quay lưng lại với ổ điện, vui vẻ lắp ráp tiếp robot. Bố đi qua dùng nút bịt an toàn gắn chặt vào ổ điện.
                            Voice Narrator: "Hoan hô bé! Ổ điện không phải là đồ chơi, tránh xa ổ điện là an toàn nhất!"
                            Reward: Bé biết tránh xa ổ điện! +1 Safety Star.
                            """)
                    ]),
                new SmartStepsSituationSeed(
                    Title: "Bài 3: Cơn nghiện ấn nút",
                    Topic: "An toàn nước nóng",
                    Intro: "Bé học cách tránh xa bình nước nóng và không tự ý nghịch nút bấm.",
                    OrderIndex: 3,
                    SkillName: "An toàn nước nóng",
                    SkillDescription: "Nhận biết mối nguy hại từ thiết bị gia dụng có chứa nước sôi/nhiệt độ cao; kiềm chế hành vi tò mò nguy hiểm.",
                    ParentPractice: "Hãy chỉ cho bé phích nước hoặc bình thủy trong nhà và dạy bé từ Nóng kèm hành động rụt tay lại.",
                    RiskAlert: "Trẻ không định nghịch nước nóng, trẻ chỉ thích cảm giác được ấn nút hoặc gạt cần. Hãy luôn bật khóa an toàn trẻ em trên các thiết bị này.",
                    Flashcard: new SmartStepsFlashcardSeed(
                        Question: "Bình thủy đang chứa nước rất nóng. Con sẽ làm gì?",
                        OptionA: "Nhấn thử cái nút đỏ xem chuyện gì xảy ra.",
                        OptionB: "Tránh xa chiếc bình và đi tìm mẹ.",
                        CorrectAnswer: "B",
                        CorrectFeedback: "Giỏi lắm! Bé đã nhận biết được nước nóng nguy hiểm và không nghịch nút bấm lung tung!",
                        WrongFeedback: "Nước trong bình cực kỳ nóng, ấn nút có thể làm nước sôi tràn ra gây bỏng tay bé!"),
                    Steps:
                    [
                        new SmartStepsSituationStepSeed(
                            StepType: "Intro",
                            OrderIndex: 1,
                            MediaUrl: "cross-road-intro_tnrhmy.mp4",
                            Content:
                            """
                            Bối cảnh: Mẹ vừa đun nước xong để pha sữa. Chiếc bình thủy điện được đặt tạm trên một chiếc bàn thấp ở phòng bếp.
                            Opening Animation: Chiếc bình thủy điện có cái nút nhấn màu đỏ phát sáng. Bé đi ngang qua và bị thu hút bởi cái nút bấm đó.
                            Voice POV của bé: "Wow, cái nút màu đỏ này phát sáng đẹp quá! Giống như nút bấm phóng tên lửa của phi hành gia vậy, mình phải bấm thử mới được!"
                            Voice người hướng dẫn: "Dừng lại đã bé ơi! Bình thủy đang chứa nước rất nóng đấy. Con sẽ làm gì?"
                            """),
                        new SmartStepsSituationStepSeed("Flashcard", 2, null, "A. Nhấn thử cái nút đỏ xem chuyện gì xảy ra. B. Tránh xa chiếc bình và đi tìm mẹ."),
                        new SmartStepsSituationStepSeed(
                            StepType: "Story",
                            OrderIndex: 3,
                            MediaUrl: "cross-road-wrong_fnc8fg.mp4",
                            Content:
                            """
                            Consequence: Bé ấn mạnh vào nút đỏ, nước sôi phun ra từ vòi trúng vào tay bé. Màn hình hiện hơi nước nóng, tay nhân vật đỏ sưng tấy.
                            Voice Narrator: "Ôi không! Nước trong bình cực kỳ nóng, ấn nút làm nước sôi tràn ra gây bỏng tay bé rồi!"
                            Voice hướng dẫn sửa sai: "Khi thấy bình nước nóng, con tuyệt đối không được tự ý ấn nút hay nghịch ngợm nhé!"
                            """),
                        new SmartStepsSituationStepSeed(
                            StepType: "Result",
                            OrderIndex: 4,
                            MediaUrl: "cross-road-correct_r36izw.mp4",
                            Content:
                            """
                            Good outcome: Bé rụt tay lại, không bấm nút nữa mà chạy ra phòng khách tìm mẹ. Mẹ dắt tay bé và khen ngợi vì bé biết tự bảo vệ mình.
                            Voice Narrator: "Giỏi lắm! Bé đã nhận biết được nước nóng nguy hiểm và không nghịch nút bấm lung tung!"
                            Reward: Bé không nghịch thiết bị nước nóng! +1 Safety Star.
                            """)
                    ])
            ]),
        new SmartStepsIslandSeed(
            Name: "Environmental Safety",
            Description: "Level 2 - An toàn môi trường",
            OrderIndex: 2,
            Situations:
            [
                new SmartStepsSituationSeed(
                    Title: "Bài 1: Qua đường an toàn",
                    Topic: "An toàn giao thông",
                    Intro: "Bé học cách chờ đèn xanh, nắm tay người lớn và nhìn hai bên trước khi qua đường.",
                    OrderIndex: 1,
                    SkillName: "An toàn giao thông",
                    SkillDescription: "Biết chờ đèn xanh trước khi qua đường.",
                    ParentPractice: "Hôm nay khi ra đường hãy hỏi bé đèn màu nào được đi.",
                    RiskAlert: "Bé vẫn hay quên nhìn hai bên trước khi qua đường.",
                    Flashcard: new SmartStepsFlashcardSeed(
                        Question: "Xe đang chạy rất đông. Con nên làm gì trước khi qua đường?",
                        OptionA: "Chạy nhanh qua đường.",
                        OptionB: "Đứng lại chờ đèn xanh.",
                        CorrectAnswer: "B",
                        CorrectFeedback: "Giỏi lắm! Chúng ta luôn chờ đèn xanh để qua đường an toàn!",
                        WrongFeedback: "Qua đường khi đèn đỏ rất nguy hiểm! Mình phải chờ đèn xanh và nhìn hai bên."),
                    Steps:
                    [
                        new SmartStepsSituationStepSeed("Intro", 1, null, "Bối cảnh: Bé đi bộ cùng mẹ trên đường về nhà. Phía bên kia đường có tiệm kem rất hấp dẫn. Xe máy chạy qua liên tục và đèn giao thông đang màu đỏ."),
                        new SmartStepsSituationStepSeed("Flashcard", 2, null, "A. Chạy nhanh qua đường. B. Đứng lại chờ đèn xanh."),
                        new SmartStepsSituationStepSeed("Story", 3, null, "Consequence: Bé chạy xuống đường, còi xe kêu liên tục, xe thắng gấp và màn hình rung nhẹ. Narrator: Qua đường khi đèn đỏ rất nguy hiểm."),
                        new SmartStepsSituationStepSeed("Result", 4, null, "Good outcome: Bé đứng cạnh mẹ, chờ đèn xanh bật rồi hai mẹ con nắm tay qua đường. Reward: Bé biết chờ đèn xanh! +1 Safety Star.")
                    ]),
                new SmartStepsSituationSeed(
                    Title: "Bài 2: Bị lạc trong siêu thị",
                    Topic: "Xử lý khi bị lạc",
                    Intro: "Bé học cách đứng yên và tìm nhân viên giúp đỡ khi không thấy ba mẹ.",
                    OrderIndex: 2,
                    SkillName: "Xử lý khi bị lạc",
                    SkillDescription: "Biết tìm người giúp đỡ khi bị lạc.",
                    ParentPractice: "Hãy hỏi bé: nếu bị lạc trong siêu thị thì con sẽ làm gì?",
                    RiskAlert: "Bé vẫn chọn chạy đi tìm mẹ khi bị lạc.",
                    Flashcard: new SmartStepsFlashcardSeed(
                        Question: "Nếu bị lạc trong siêu thị, con nên làm gì?",
                        OptionA: "Chạy đi tìm mẹ khắp nơi.",
                        OptionB: "Đứng yên và tìm nhân viên giúp đỡ.",
                        CorrectAnswer: "B",
                        CorrectFeedback: "Giỏi lắm! Nhờ người lớn giúp đỡ là cách an toàn nhất.",
                        WrongFeedback: "Chạy lung tung có thể làm mình lạc xa hơn! Nếu bị lạc, hãy đứng yên và tìm người lớn đáng tin cậy."),
                    Steps:
                    [
                        new SmartStepsSituationStepSeed("Intro", 1, null, "Bối cảnh: Bé đang đi siêu thị cùng mẹ. Bé nhìn đồ chơi, quay lại và không thấy mẹ đâu."),
                        new SmartStepsSituationStepSeed("Flashcard", 2, null, "A. Chạy đi tìm mẹ khắp nơi. B. Đứng yên và tìm nhân viên giúp đỡ."),
                        new SmartStepsSituationStepSeed("Story", 3, null, "Consequence: Bé chạy lung tung, càng đi càng xa và nhạc trở nên căng thẳng. Narrator: Chạy lung tung có thể làm mình lạc xa hơn."),
                        new SmartStepsSituationStepSeed("Result", 4, null, "Good outcome: Bé gặp cô nhân viên, cô phát loa và mẹ tìm thấy bé. Reward: Bé biết xử lý khi bị lạc!")
                    ]),
                new SmartStepsSituationSeed(
                    Title: "Bài 3: Hồ nước / hồ bơi",
                    Topic: "An toàn hồ nước",
                    Intro: "Bé học cách tránh xa mép nước và tìm người lớn khi đồ chơi rơi xuống hồ.",
                    OrderIndex: 3,
                    SkillName: "An toàn hồ nước",
                    SkillDescription: "Biết tìm người lớn giúp đỡ khi gặp nguy hiểm gần hồ nước hoặc hồ bơi.",
                    ParentPractice: "Hãy hỏi bé: nếu đồ chơi rơi xuống hồ nước thì con sẽ làm gì?",
                    RiskAlert: "Bé vẫn có xu hướng tự đến gần mép nước.",
                    Flashcard: new SmartStepsFlashcardSeed(
                        Question: "Hồ nước có thể rất sâu và trơn. Con nên làm gì bây giờ?",
                        OptionA: "Tự chạy lại lấy bóng.",
                        OptionB: "Tìm người lớn giúp đỡ.",
                        CorrectAnswer: "B",
                        CorrectFeedback: "Giỏi lắm! Khi gặp nơi nguy hiểm, hãy nhờ người lớn giúp đỡ.",
                        WrongFeedback: "Chơi gần hồ nước một mình rất nguy hiểm! Nếu đồ chơi rơi xuống nước, mình phải tìm người lớn giúp đỡ."),
                    Steps:
                    [
                        new SmartStepsSituationStepSeed("Intro", 1, null, "Bối cảnh: Bé đang tự chơi bóng trong công viên gần hồ nước. Quả bóng lăn nhanh về phía hồ rồi rơi xuống nước và nổi gần mép hồ."),
                        new SmartStepsSituationStepSeed("Flashcard", 2, null, "A. Tự chạy lại lấy bóng. B. Tìm người lớn giúp đỡ."),
                        new SmartStepsSituationStepSeed("Story", 3, null, "Consequence: Bé chạy tới mép hồ, cúi xuống lấy bóng. Mặt đất trơn làm bé bị trượt chân, nước bắn lên và bé sợ hãi."),
                        new SmartStepsSituationStepSeed("Result", 4, null, "Good outcome: Bé chạy tới chú bảo vệ công viên. Chú bảo vệ dùng cây vợt dài lấy bóng lên giúp bé. Reward: Bé biết tránh xa hồ nước sâu! +1 Safety Star.")
                    ])
            ]),
        new SmartStepsIslandSeed(
            Name: "Social Safety",
            Description: "Level 3 - An toàn xã hội",
            OrderIndex: 3,
            Situations:
            [
                new SmartStepsSituationSeed(
                    Title: "Bài 1: Người lạ biết tên bé",
                    Topic: "Kỹ năng đối phó kẻ gian tinh vi",
                    Intro: "Bé học cách cảnh giác với người lạ dù người đó biết tên mình hoặc nói quen ba mẹ.",
                    OrderIndex: 1,
                    SkillName: "Cảnh giác người lạ",
                    SkillDescription: "Cảnh giác với người lạ giả danh người quen.",
                    ParentPractice: "Ba mẹ hãy cùng bé tạo ra một mật khẩu bí mật. Dặn bé chỉ đi theo ai đọc đúng mật khẩu này.",
                    RiskAlert: "Bé rất dễ mất cảnh giác khi người lạ ăn mặc đẹp, tỏ ra thân thiện và biết rõ tên bé.",
                    Flashcard: new SmartStepsFlashcardSeed(
                        Question: "Người lạ nói mẹ nhờ đến đón. Con sẽ xử lý thế nào?",
                        OptionA: "Tin lời cô, bước lên xe ô tô để về với mẹ.",
                        OptionB: "Lùi lại, nói to \"Cháu không đi!\" và chạy vào trường báo cô giáo.",
                        CorrectAnswer: "B",
                        CorrectFeedback: "Quá xuất sắc! Cảnh giác và chạy đi tìm người lớn tin cậy là cách bảo vệ mình thông minh nhất!",
                        WrongFeedback: "Kẻ xấu có thể giả vờ quen biết mẹ con để lừa bắt cóc con đấy!"),
                    Steps:
                    [
                        new SmartStepsSituationStepSeed("Intro", 1, null, "Bối cảnh: Bé đang đứng đợi mẹ ở cổng trường. Một người phụ nữ ăn mặc lịch sự, đi xe ô tô đến, gọi đúng tên bé và tươi cười vẫy gọi."),
                        new SmartStepsSituationStepSeed("Flashcard", 2, null, "A. Tin lời cô, bước lên xe ô tô để về với mẹ. B. Lùi lại, nói to \"Cháu không đi!\" và chạy vào trường báo cô giáo."),
                        new SmartStepsSituationStepSeed("Story", 3, null, "Consequence: Bé vừa bước lên xe, cửa xe đóng sập lại, xe lao vút đi và màn hình nhấp nháy đỏ. Narrator: Rất nguy hiểm! Kẻ xấu có thể giả vờ quen biết mẹ con."),
                        new SmartStepsSituationStepSeed("Result", 4, null, "Good outcome: Bé lùi lại, chạy thẳng vào cổng trường gọi cô giáo. Người phụ nữ lạ thấy vậy vội vàng bỏ đi. Reward: Bé không mắc mưu kẻ xấu! +1 Brave Star.")
                    ]),
                new SmartStepsSituationSeed(
                    Title: "Bài 2: Lời thách đố của bạn bè",
                    Topic: "Kỹ năng đối mặt áp lực đồng trang lứa",
                    Intro: "Bé học cách nói không với lời thách đố nguy hiểm và tìm người lớn giúp đỡ.",
                    OrderIndex: 2,
                    SkillName: "Từ chối áp lực bạn bè",
                    SkillDescription: "Từ chối áp lực bạn bè và không làm việc nguy hiểm để chứng tỏ bản thân.",
                    ParentPractice: "Đóng vai bạn bè rủ bé làm việc sai, ví dụ lén ăn vụng kẹo trước bữa cơm, xem bé có dám từ chối ba mẹ không.",
                    RiskAlert: "Ở độ tuổi này, bé rất sợ bị bạn bè chê cười hoặc tẩy chay, nên dễ nhắm mắt làm liều.",
                    Flashcard: new SmartStepsFlashcardSeed(
                        Question: "Các bạn đang ép con làm một việc nguy hiểm. Con nên làm gì?",
                        OptionA: "Nhắm mắt trèo rào sang lấy bóng để chứng tỏ mình không nhát gan.",
                        OptionB: "Kiên quyết từ chối bạn và đi tìm người lớn nhờ lấy giúp.",
                        CorrectAnswer: "B",
                        CorrectFeedback: "Tuyệt vời! Biết nói không với trò chơi nguy hiểm chứng tỏ con rất trưởng thành!",
                        WrongFeedback: "Cố chứng tỏ bản thân bằng cách làm việc nguy hiểm không phải là dũng cảm đâu!"),
                    Steps:
                    [
                        new SmartStepsSituationStepSeed("Intro", 1, null, "Bối cảnh: Bé đang chơi đá bóng cùng nhóm bạn. Quả bóng bay qua hàng rào rơi vào sân nhà hàng xóm có nuôi chó dữ."),
                        new SmartStepsSituationStepSeed("Flashcard", 2, null, "A. Nhắm mắt trèo rào sang lấy bóng để chứng tỏ mình không nhát gan. B. Kiên quyết từ chối bạn và đi tìm người lớn nhờ lấy giúp."),
                        new SmartStepsSituationStepSeed("Story", 3, null, "Consequence: Bé leo lên hàng rào, trượt chân té ngã. Con chó chạy ra sủa ầm ĩ và bé khóc vì sợ và đau."),
                        new SmartStepsSituationStepSeed("Result", 4, null, "Good outcome: Bé lắc đầu kiên quyết nói không, chạy đi gọi chú chủ nhà. Chú mở cửa lấy bóng ra, cả nhóm bạn nể phục bé. Reward: Bé biết nói KHÔNG với nguy hiểm! +1 Shield Star.")
                    ]),
                new SmartStepsSituationSeed(
                    Title: "Bài 3: Chiếc ví bị đánh rơi",
                    Topic: "Kỹ năng kiểm soát cám dỗ và trung thực",
                    Intro: "Bé học cách trung thực trả lại của rơi dù không có ai nhìn thấy.",
                    OrderIndex: 3,
                    SkillName: "Trung thực",
                    SkillDescription: "Vượt qua lòng tham, trung thực trả lại của rơi.",
                    ParentPractice: "Ba mẹ thử cố tình đánh rơi một tờ tiền lẻ trong phòng bé, xem bé sẽ giữ lấy hay đem trả lại cho ba mẹ.",
                    RiskAlert: "Bé dễ bị cám dỗ bởi suy nghĩ không ai nhìn thấy thì không sao.",
                    Flashcard: new SmartStepsFlashcardSeed(
                        Question: "Nhặt được đồ không phải của mình, mà lại không có ai nhìn thấy. Con sẽ quyết định thế nào?",
                        OptionA: "Lén nhặt chiếc ví giấu vào túi quần để mang về.",
                        OptionB: "Chạy nhanh nhặt lên và lớn tiếng gọi: \"Cô ơi, cô đánh rơi ví này!\"",
                        CorrectAnswer: "B",
                        CorrectFeedback: "Rất đáng tự hào! Sự trung thực của con đáng giá hơn bất kỳ món đồ chơi nào trên đời!",
                        WrongFeedback: "Lấy đồ của người khác sẽ làm họ rất buồn khổ, và chính con cũng cảm thấy tội lỗi."),
                    Steps:
                    [
                        new SmartStepsSituationStepSeed("Intro", 1, null, "Bối cảnh: Bé đang đi rửa tay trong khu vui chơi thì thấy một người đi trước làm rơi chiếc ví. Người đó đi khuất, chiếc ví mở hé ra và bên trong có nhiều tờ tiền."),
                        new SmartStepsSituationStepSeed("Flashcard", 2, null, "A. Lén nhặt chiếc ví giấu vào túi quần để mang về. B. Chạy nhanh nhặt lên và lớn tiếng gọi: \"Cô ơi, cô đánh rơi ví này!\""),
                        new SmartStepsSituationStepSeed("Story", 3, null, "Consequence: Bé cất ví. Lát sau thấy người phụ nữ quay lại khóc lóc nhờ bảo vệ tìm ví vì có giấy tờ nhập viện cho em bé. Bé cúi mặt hối hận."),
                        new SmartStepsSituationStepSeed("Result", 4, null, "Good outcome: Bé nhặt ví chạy theo đưa tận tay. Người phụ nữ mừng rỡ cảm ơn và tặng bé một sticker Ngôi Sao. Reward: Bé là em bé trung thực! +1 Honesty Star.")
                    ])
            ])
    ];
}

internal sealed record SmartStepsIslandSeed(
    string Name,
    string Description,
    int OrderIndex,
    IReadOnlyList<SmartStepsSituationSeed> Situations);

internal sealed record SmartStepsSituationSeed(
    string Title,
    string Topic,
    string Intro,
    int OrderIndex,
    string SkillName,
    string SkillDescription,
    string ParentPractice,
    string RiskAlert,
    SmartStepsFlashcardSeed Flashcard,
    IReadOnlyList<SmartStepsSituationStepSeed> Steps);

internal sealed record SmartStepsSituationStepSeed(
    string StepType,
    int OrderIndex,
    string? MediaUrl,
    string Content);

internal sealed record SmartStepsFlashcardSeed(
    string Question,
    string OptionA,
    string OptionB,
    string CorrectAnswer,
    string CorrectFeedback,
    string WrongFeedback,
    string? QuestionVoiceUrl = null,
    string? OptionAVoiceUrl = null,
    string? OptionBVoiceUrl = null);
