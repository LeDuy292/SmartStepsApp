using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartStepsServer.Migrations;

[Migration("20260611000000_UpdateCloudinaryMediaPaths")]
public partial class UpdateCloudinaryMediaPaths : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 1,
            column: "MediaUrl",
            value: "Safety_smallitems_intro_cw1tlh.mp4");

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 3,
            column: "MediaUrl",
            value: "Safety_smallitems_wrong_pjogba.mp4");

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 4,
            column: "MediaUrl",
            value: "Safety_smallitems_correct_u5ubla.mp4");

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 5,
            column: "MediaUrl",
            value: "Safety_stranger_Intro_chanol.mp4");

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 7,
            column: "MediaUrl",
            value: "Safety_stranger_wrong_dgsjbj.mp4");

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 8,
            column: "MediaUrl",
            value: "Safety_stranger_correct_rkwehk.mp4");

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 9,
            column: "MediaUrl",
            value: "cross-road-intro_tnrhmy.mp4");

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 11,
            column: "MediaUrl",
            value: "cross-road-wrong_fnc8fg.mp4");

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 12,
            column: "MediaUrl",
            value: "cross-road-correct_r36izw.mp4");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 1,
            column: "MediaUrl",
            value: "Lession1/Videos/lesson1-intro.mp4");

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 3,
            column: "MediaUrl",
            value: "Lession1/Videos/lesson1-wrong.mp4");

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 4,
            column: "MediaUrl",
            value: "Lession1/Videos/lesson1-correct.mp4");

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 5,
            column: "MediaUrl",
            value: null);

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 7,
            column: "MediaUrl",
            value: null);

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 8,
            column: "MediaUrl",
            value: null);

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 9,
            column: "MediaUrl",
            value: null);

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 11,
            column: "MediaUrl",
            value: null);

        migrationBuilder.UpdateData(
            table: "SituationStep",
            keyColumn: "StepId",
            keyValue: 12,
            column: "MediaUrl",
            value: null);
    }
}
