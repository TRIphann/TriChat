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
        [HttpPost("generate")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(ApiResponse<OtpResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<ErrorDetail>), StatusCodes.Status422UnprocessableEntity)]
        public async Task<IActionResult> GenerateOtp([FromBody] GenerateOtpRequest request)
        {
            _logger.LogInformation("OTP generate request received for email: {Email}", request.Email);
            try
            {
                var (otp, emailSent) = await otpService.GenerateOtpAsync(request.Email);
                _logger.LogInformation("OTP generate SUCCESS for email: {Email}, emailSent: {EmailSent}", request.Email, emailSent);
                
                // Return OTP in response so client can display it if email fails
                return Ok(ApiResponse<OtpResponse>.SuccessResponse(new OtpResponse
                {
                    Email = request.Email,
                    Otp = emailSent ? null : otp // Only return OTP if email failed
                }, emailSent ? "OTP đã được gửi qua email" : "Email không khả dụng, mã OTP đã được hiển thị để xác minh"));
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
                await otpService.VerifyOtpAsync(request.Email, request.Otp, request.CachedOtp);
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
