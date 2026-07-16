using backend.Exceptions;
using backend.common;
using backend.dtos.Request;
using backend.dtos.Response;
using backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    /// <summary>
    /// Controller quản lý OTP (One-Time Password) cho việc khôi phục mật khẩu hoặc xác minh email.
    /// </summary>
    [Route("api/otp")]
    [ApiController]
    public class OtpController(OtpService otpService, ILogger<OtpController> logger) : ControllerBase
    {
        private readonly ILogger<OtpController> _logger = logger;
        /// <summary>
        /// Tạo mã OTP mới và gửi qua email đăng ký.
        /// </summary>
        /// <remarks>
        /// Endpoint này không yêu cầu Token JWT (cho phép nặc danh) để dùng cho luồng Quên mật khẩu / Xác minh email.
        /// </remarks>
        /// <param name="request">Thông tin yêu cầu tạo OTP gồm Email</param>
        /// <returns>Thông tin OTP đã được tạo (dành cho mục đích phát triển/xác thực)</returns>
        /// <response code="200">Gửi OTP thành công</response>
        /// <response code="422">Địa chỉ email không hợp lệ hoặc bị trống</response>
        [HttpPost("generate")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(ApiResponse<OtpResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
        public async Task<IActionResult> GenerateOtp([FromBody] GenerateOtpRequest request)
        {
            _logger.LogInformation("OTP generate request received for email: {Email}", request.Email);
            try
            {
                await otpService.GenerateOtpAsync(request.Email);
                _logger.LogInformation("OTP generate SUCCESS for email: {Email}", request.Email);
                return Ok(ApiResponse<OtpResponse>.SuccessResponse(new OtpResponse
                {
                    Email = request.Email
                }));
            }
            catch (AppException ex)
            {
                _logger.LogWarning(ex, "OTP generate FAILED for email: {Email} with AppException", request.Email);
                return StatusCode(422, ApiResponse<object>.ErrorResponse(422, ex.Message));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "OTP generate FAILED for email: {Email} with unexpected error", request.Email);
                return StatusCode(500, ApiResponse<object>.ErrorResponse(500, "Lỗi hệ thống: " + ex.Message));
            }
        }

        /// <summary>
        /// Xác thực mã OTP người dùng gửi lên.
        /// </summary>
        /// <remarks>
        /// Endpoint này không yêu cầu Token JWT để cho phép xác thực mã OTP trước khi thiết lập lại mật khẩu mới.
        /// </remarks>
        /// <param name="request">Thông tin xác thực OTP gồm Email và mã OTP</param>
        /// <returns>Kết quả xác thực OTP thành công</returns>
        /// <response code="200">Xác thực OTP thành công</response>
        /// <response code="401">Mã OTP không hợp lệ hoặc đã hết hạn</response>
        /// <response code="422">Dữ liệu yêu cầu thiếu hoặc không hợp lệ</response>
        [HttpPost("verify")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest request)
        {
            _logger.LogInformation("OTP verify request received for email: {Email}", request.Email);
            try
            {
                await otpService.VerifyOtpAsync(request.Email, request.Otp);
                _logger.LogInformation("OTP verify SUCCESS for email: {Email}", request.Email);
                return Ok(ApiResponse<object>.SuccessResponse(true, "OTP verified successfully"));
            }
            catch (AppException ex)
            {
                _logger.LogWarning(ex, "OTP verify FAILED for email: {Email} with AppException", request.Email);
                return StatusCode(401, ApiResponse<object>.ErrorResponse(401, ex.Message));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "OTP verify FAILED for email: {Email} with unexpected error", request.Email);
                return StatusCode(500, ApiResponse<object>.ErrorResponse(500, "Lỗi hệ thống: " + ex.Message));
            }
        }
    }
}
