# Godot Basic Character Controller and Enemy AI

Project game 3D viết bằng Godot, mở rộng từ mẫu third-person controller cơ bản. Người chơi phải thu thập đủ crystal, tránh enemy và bẫy gấu, sau đó đi tới khu vực escape để chiến thắng.

## Tính năng

- Điều khiển nhân vật góc nhìn thứ ba.
- Camera có va chạm và zoom bằng con lăn chuột.
- Enemy AI với các trạng thái `IDLE`, `PATROL`, `CHASE` và `DEAD`.
- Enemy phát hiện người chơi bằng khoảng cách, góc nhìn và raycast.
- Thu thập 4 crystal để mở khu vực escape.
- Bẫy gấu làm chậm người chơi hoặc enemy trong thời gian ngắn.
- HUD hiển thị máu và tiến độ crystal.
- Nhạc nền, hiệu ứng chạy, trúng đòn, phát hiện enemy, hạ enemy, bẫy, thắng và thua.

## Yêu cầu

- Godot 4.7.x hoặc phiên bản tương thích.
- Renderer Forward+.

## Cách chạy

1. Mở Godot Project Manager.
2. Chọn **Import** và mở file `project.godot`.
3. Nhấn **Run Project** hoặc nhấn `F6` / `F5` trong Godot.

Scene chính là `main.tscn`.

## Điều khiển

| Hành động | Phím |
|---|---|
| Di chuyển | `W` `A` `S` `D` hoặc phím mũi tên |
| Nhảy | `Space` hoặc `Enter` |
| Xoay camera | Di chuyển chuột |
| Zoom | Con lăn chuột |
| Hạ enemy | Nhảy lên đầu enemy |

## Cấu trúc chính

- `Player.gd`: di chuyển, nhảy, máu và trạng thái người chơi.
- `Enemy.gd`: state machine và AI phát hiện/truy đuổi.
- `Sound.gd`: autoload quản lý nhạc và hiệu ứng âm thanh trong `res://sound/`.
- `GameManager.gd`: quản lý crystal và điều kiện chiến thắng.
- `main.tscn`: map và các đối tượng gameplay chính.

## Nguồn âm thanh

Các nguồn dưới đây được lấy từ metadata của các file MP3 trong `res://sound/`:

| File | Nguồn |
|---|---|
| `lose.mp3` | [GTA V Wasted/Busted - Sound Effect (HD)](https://www.youtube.com/watch?v=K3kFQHKE0LA) — Gaming Sound FX |
| `run.mp3` | [Running SFX Sound Effect 2025](https://www.youtube.com/watch?v=gT8u7iNJV_I) — FX VAULT |
| `win.mp3` | [WIN sound effect no copyright](https://www.youtube.com/watch?v=rr5CMS2GtCY) — JG Green Screen |
| `bg.mp3`, `enemy_spotted.mp3`, `hit.mp3`, `kill.mp3`, `trap.mp3` | Chưa có URL nguồn được xác minh |

Hãy kiểm tra điều khoản sử dụng và giấy phép của từng video trước khi phát hành bản build.

## Tài nguyên khác

Model, texture và map nằm trong các thư mục `GLTF/`, `model/`, `map/` và `sky/`. Giấy phép của một số model được lưu trong các file `license.txt` tương ứng.

## Ghi chú

Addon `addons/godot_ai` được dùng cho công cụ phát triển. Nên tắt addon và autoload `_mcp_game_helper` trước khi export bản phát hành.
