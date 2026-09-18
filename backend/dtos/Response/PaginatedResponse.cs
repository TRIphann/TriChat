namespace backend.dtos.Response;

/// <summary>
/// Wrapper cho dữ liệu phân trang. Frontend dùng HasMore để biết còn
/// request thêm được nữa không, hoặc tự tính bằng Offset + Items.Count &lt; Total.
/// </summary>
/// <typeparam name="T">Kiểu phần tử trong page</typeparam>
public class PaginatedResponse<T>
{
    public List<T> Items { get; init; } = new();

    /// <summary>Tổng số bản ghi thỏa điều kiện (trước khi phân trang).</summary>
    public int Total { get; init; }

    /// <summary>Số bản ghi tối đa trong 1 page.</summary>
    public int Limit { get; init; }

    /// <summary>Vị trí bắt đầu của page hiện tại (zero-based).</summary>
    public int Offset { get; init; }

    /// <summary>True khi còn page tiếp theo (Offset + Items.Count &lt; Total).</summary>
    public bool HasMore { get; init; }
}
