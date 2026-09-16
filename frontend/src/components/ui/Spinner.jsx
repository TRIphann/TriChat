import './spinner.css';

export default function Spinner({ size = 24, thickness = 2.4 }) {
  return (
    <span
      className="spinner"
      style={{ width: size, height: size, borderWidth: thickness }}
      aria-label="Đang tải"
    />
  );
}
