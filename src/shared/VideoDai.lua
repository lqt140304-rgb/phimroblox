--[[
	WHAT IF (bản dài ~15 phút): Nếu trọng lực Trái Đất giảm một nửa trong 7 ngày?
	ModuleScript trong ReplicatedStorage, tên "VideoDai". Cần thêm module "Video" (bản Short) để dùng lại quảng trường.
	Kịch bản: docs/WHAT-IF-TRONG-LUC-DAI.md

	CHƯƠNG = 0  → chạy liền 18 chương (~15 phút)
	CHƯƠNG = 5  → chỉ quay chương 5 (khuyên dùng: quay từng chương rồi ghép trong CapCut)
]]

local CHUONG = 0

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Video = require(script.Parent:WaitForChild("Video"))

local VD = {}

-- dàn diễn viên = dàn bản Short + nhân vật mới
local CAST = table.clone(Video.CAST)
CAST.Minh = { skin = "#efc8a8", hair = "curtain", hairColor = "#1e1a18", height = 1.04, outfit = { top = "shirt", sleeves = "long", topColor = "#f2f2f2", stripe = "#9fb3c8", bottom = "pants", bottomColor = "#2f3a4a", shoes = "#3a2a20", acc = { "watch" } } }
CAST.CoXoi = { skin = "#d8a280", hair = "bun", hairColor = "#2a2626", female = true, height = 0.86, proportion = 0.2, outfit = "co_hoa_ba_ba" }
CAST.ChuPho = { skin = "#d6a07c", hair = "short", hairColor = "#2a2420", height = 1.0, width = 1.12, outfit = { top = "tee", sleeves = "short", topColor = "#f2f2f2", bottom = "pants", bottomColor = "#3a3a3a", shoes = "#2a2a2a", acc = { "apron" } } }
CAST.OngLao = { skin = "#b07a56", hair = "short", hairColor = "#d0d0d0", height = 0.94, width = 1.0, outfit = { top = "baba", sleeves = "long", topColor = "#5a6a7a", bottom = "pants", bottomColor = "#2a2a2a", shoes = "#2a2a2a", acc = {} } }
CAST.YTa = { skin = "#f4d5c0", hair = "ponytail", hairColor = "#2a1d18", female = true, lips = "#c07070", height = 0.94, outfit = { top = "shirt", sleeves = "short", topColor = "#e8f4f8", bottom = "pants", bottomColor = "#e8f4f8", shoes = "#ffffff", acc = {} } }
CAST.Shipper = { skin = "#d6a07c", hair = "short", hairColor = "#1a1714", height = 1.02, outfit = { top = "jacket", sleeves = "long", topColor = "#2f2f2f", jacketColor = "#1b7a3e", bottom = "jeans", bottomColor = "#22252a", shoes = "#2a2a2a", acc = { "backpack" } } }
CAST.CauThu1 = { skin = "#c98e68", hair = "short", hairColor = "#161412", height = 1.06, outfit = { top = "tee", sleeves = "short", topColor = "#c8322f", bottom = "shorts", bottomColor = "#f2f2f2", shoes = "#e8c547", acc = {} } }
CAST.CauThu2 = { skin = "#efc8a8", hair = "spiky", hairColor = "#2a1d18", height = 1.02, outfit = { top = "tee", sleeves = "short", topColor = "#2f6ab0", bottom = "shorts", bottomColor = "#1d1d22", shoes = "#f2f2f2", acc = {} } }
CAST.ThuMon = { skin = "#dcae8a", hair = "short", hairColor = "#1e1a18", height = 1.1, outfit = { top = "tee", sleeves = "long", topColor = "#e8c547", bottom = "shorts", bottomColor = "#1d1d22", shoes = "#2a2a2a", acc = {} } }
VD.CAST = CAST

-- Lời kể từng chương (tự sinh từ docs/WHAT-IF-TRONG-LUC-DAI.md). dur = thời lượng ước tính (giây);
-- khi có file giọng thật, thay dur bằng độ dài từng câu.
local NARR = {
	{
		{ text = "Ngày thứ bảy. Mười giờ sáng. Cả quảng trường đang lơ lửng trên không…", big = "NGÀY 7 · 10:00", dur = 4.43 },
		{ text = "…và trọng lực trở lại.", big = "", dur = 1.97 },
		{ text = "Bảy ngày trước, chuyện này nghe như một trò vui. Ai cũng cười, ai cũng nhảy. Nhưng đến cuối video, bạn sẽ thấy có một thứ đã bị lấy đi mãi mãi. Và nó đang treo ngay trên đầu bạn, mỗi đêm.", big = "", dur = 12.08 },
		{ text = "Hôm nay, chúng ta sẽ sống qua bảy ngày Trái Đất mất một nửa trọng lực, từng ngày một.", big = "NẾU TRỌNG LỰC GIẢM MỘT NỬA", dur = 5.79 },
	},
	{
		{ text = "Trước hết, luật chơi. Chỉ có lực hút của Trái Đất yếu đi một nửa. Mặt Trời, Mặt Trăng vẫn hút như cũ.", big = "Chỉ Trái Đất", dur = 6.88 },
		{ text = "Mọi vật vẫn giữ nguyên khối lượng. Bạn không gầy đi, chỉ là… nhẹ đi.", big = "Khối lượng giữ nguyên", dur = 4.7 },
		{ text = "Thử thách kéo dài đúng bảy ngày. Sau đó, mọi thứ trở lại bình thường. Hoặc ít nhất… là gần như bình thường.", big = "7 NGÀY", dur = 6.88 },
		{ text = "Và trước khi bắt đầu, hãy thử đoán xem: trong bảy ngày đó, thứ gì sẽ gây thiệt hại lớn nhất? Giao thông? Thời tiết? Hay một thứ bạn chưa từng nghĩ tới? Ghi đáp án vào bình luận, rồi xem đến cuối để biết bạn đúng hay sai.", big = "A · B · C ?", dur = 13.99 },
	},
	{
		{ text = "Sáu giờ sáng ngày một. Bạn tỉnh dậy, thấy người nhẹ bẫng, như vừa ngủ một giấc thật sâu.", big = "", dur = 5.79 },
		{ text = "Bạn bước lên cân. Năm mươi lăm cân… giờ chỉ còn hơn hai mươi bảy.", big = "55 kg → 27,5 kg", dur = 4.7 },
		{ text = "Nhưng điều đầu tiên bạn thực sự cảm thấy, lại là… tai bạn. Ù một cái, giống lúc máy bay hạ cánh.", big = "", dur = 6.61 },
		{ text = "Vì không khí cũng có trọng lượng. Cả bầu khí quyển đè lên đầu bạn giờ chỉ nặng bằng một nửa, nên áp suất ở mặt đất cũng giảm một nửa, chỉ trong tích tắc.", big = "ÁP SUẤT 50%", dur = 10.16 },
		{ text = "Bạn vào nhà tắm, mở vòi. Nước chảy yếu hẳn. Bồn nước inox trên mái đẩy nước xuống nhờ trọng lực, nên giờ nước chảy chậm hơn khoảng ba mươi phần trăm.", big = "vòi yếu ~30%", dur = 9.34 },
		{ text = "Bạn đặt nồi nước lên bếp. Nó sôi sớm hơn bình thường, ở khoảng tám mươi mốt độ thay vì một trăm. Nghe thì tiết kiệm ga… nhưng giữ lấy suy nghĩ đó, ta sẽ quay lại chuyện này.", big = "81°C", dur = 11.26 },
	},
	{
		{ text = "Để thấy rõ thế giới mới này, hãy đi theo Minh, nhân viên văn phòng, hai mươi lăm tuổi, nhà ở tầng năm một khu tập thể cũ.", big = "MINH · 25 tuổi", dur = 8.25 },
		{ text = "Năm tầng cầu thang, ngày thường Minh leo đến tầng ba là thở. Hôm nay, anh nhún một cái lên hai bậc, rồi ba bậc. Xuống đến tầng một mà chưa đổ giọt mồ hôi nào.", big = "", dur = 10.44 },
		{ text = "Ra đầu ngõ, cô bán xôi đang gánh hai thúng xôi đầy ụ, nhẹ như gánh hai cái rổ không.", big = "", dur = 6.06 },
		{ text = "Minh ăn sáng ở quán phở quen. Bát phở nóng hổi, nhưng mỗi lần anh nhấc lên, nước dùng lại sóng sánh lâu hơn, dễ đổ hơn. Chất lỏng giờ dao động chậm hơn và lâu lắng xuống hơn.", big = "", dur = 11.26 },
		{ text = "Minh dắt xe máy ra. Cái xe nặng hơn một tạ, giờ anh nhấc bổng một đầu bằng một tay.", big = "xe 110 kg → cảm giác 55 kg", dur = 6.06 },
		{ text = "Mọi thứ đều nhẹ hơn, dễ hơn, vui hơn. Nhưng Minh chưa biết rằng cái xe máy đó sẽ khiến anh suýt mất mạng vào ngày hôm sau.", big = "", dur = 8.25 },
	},
	{
		{ text = "Buổi chiều ngày một, cả thành phố biến thành sân chơi.", big = "NGÀY 1", dur = 3.61 },
		{ text = "Cùng một lực bật, bạn nhảy cao gấp đôi và lơ lửng lâu gấp đôi. Một cú bật tại chỗ đưa bạn lên gần một mét.", big = "nhảy cao ×2", dur = 7.7 },
		{ text = "Kỷ lục nhảy cao thế giới hiện là hai mét bốn lăm. Với trọng lực một nửa, theo ước tính, xà có thể được đặt ở ba mét rưỡi, thậm chí gần bốn mét.", big = "2,45 m → ~3,7 m", dur = 9.89 },
		{ text = "Ở sân bóng rổ, những người cao một mét bảy lần đầu tiên trong đời chạm được vành rổ.", big = "", dur = 5.79 },
		{ text = "Một cú sút bóng bay xa gấp đôi. Thủ môn sẽ khóc thét.", big = "bay xa ×2", dur = 4.15 },
		{ text = "Nhưng đi bộ lại khó hơn bạn tưởng. Bạn nảy lên ở mỗi bước, như phi hành gia trên Mặt Trăng. Tốc độ đi bộ tối đa giảm còn khoảng bảy mươi phần trăm. Muốn đi nhanh, bạn phải chuyển sang nhảy cóc.", big = "", dur = 12.35 },
		{ text = "Vậy còn những con vật quanh ta thì sao? Chúng sẽ thích nghi nhanh hơn chúng ta nhiều…", big = "", dur = 5.52 },
	},
	{
		{ text = "Tối ngày một, mạng xã hội nổ tung. Trend mới: nhảy qua nóc ô tô. Trend thứ hai: lộn ba vòng trên không. Trend thứ ba: nhảy từ ban công tầng hai xuống.", big = "#NHAYQUAXE", dur = 9.62 },
		{ text = "Và đây là lúc các phòng cấp cứu bắt đầu đông người.", big = "", dur = 3.88 },
		{ text = "Nhiều người nghĩ trọng lực yếu thì rơi không đau. Nhưng nhảy từ tầng hai cao sáu mét, bạn vẫn chạm đất với tốc độ như nhảy từ độ cao ba mét bình thường. Đủ để gãy chân.", big = "6 m → như rơi 3 m", dur = 10.98 },
		{ text = "Rơi chậm hơn không có nghĩa là rơi an toàn. Bộ Y tế phát cảnh báo khẩn ngay trong đêm: không nhảy từ trên cao xuống, dù trông có vẻ dễ đến đâu.", big = "CẢNH BÁO", dur = 9.62 },
		{ text = "Còn những người không phải lo về tai nạn nhất… lại là những con vật quanh ta.", big = "", dur = 5.24 },
	},
	{
		{ text = "Con mèo nhà bạn, vốn đã nhảy giỏi, giờ phóng một phát lên tận nóc tủ lạnh. Rồi lên nóc tủ quần áo. Chẳng có chỗ nào trong nhà là an toàn nữa.", big = "", dur = 9.62 },
		{ text = "Chó thì lúng túng. Mỗi lần chạy nhanh là nó nảy lên khỏi mặt đất, trượt chân khi đổi hướng, và phải mất vài ngày mới quen.", big = "", dur = 7.98 },
		{ text = "Còn chim? Đây là điều bất ngờ. Không khí loãng đi một nửa nên cánh tạo ra ít lực nâng hơn. Nhưng cơ thể chim cũng nhẹ đi một nửa. Hai thứ triệt tiêu nhau.", big = "lực nâng ÷2 · trọng lượng ÷2", dur = 10.16 },
		{ text = "Chim và côn trùng bay gần như bình thường, thậm chí đỡ tốn sức hơn khi bay lượn tại chỗ. Trong khi con người loay hoay, bầu trời vẫn yên bình.", big = "", dur = 9.07 },
		{ text = "Nhưng dưới mặt đất, ngày hai bắt đầu bằng tiếng còi xe.", big = "", dur = 3.88 },
	},
	{
		{ text = "Ngày hai. Bảy giờ sáng. Giờ cao điểm.", big = "NGÀY 2", dur = 2.79 },
		{ text = "Bánh xe bám đường nhờ trọng lượng đè xuống. Nhẹ đi một nửa, độ bám cũng chỉ còn một nửa.", big = "độ bám ÷2", dur = 6.06 },
		{ text = "Phanh gấp, xe trượt dài gấp đôi. Khoảng cách an toàn mà bạn quen tay suốt nhiều năm, bỗng nhiên không còn an toàn nữa.", big = "quãng phanh ×2", dur = 7.43 },
		{ text = "Vào cua còn tệ hơn. Muốn không văng ra ngoài, xe phải chạy chậm hơn khoảng ba mươi phần trăm.", big = "cua chậm ~30%", dur = 6.06 },
		{ text = "Minh vẫn phóng xe như mọi ngày. Đến ngã tư, đèn vàng, anh bóp phanh. Chiếc xe trượt… và trượt… dừng lại chỉ cách đuôi xe buýt vài gang tay.", big = "", dur = 8.8 },
		{ text = "Với hàng triệu chiếc xe máy, ngày hai sẽ là ngày kẹt xe và va chạm kỷ lục, cho đến khi mọi người học lại cách lái.", big = "", dur = 7.98 },
		{ text = "Còn máy bay? Không khí loãng đi một nửa, nhưng máy bay cũng nhẹ đi một nửa. Giống như chim, máy bay vẫn cất cánh ở tốc độ gần như cũ.", big = "", dur = 9.07 },
		{ text = "Không phải ai cũng khổ vì trọng lực mới. Có những người… đang rất vui.", big = "", dur = 4.7 },
	},
	{
		{ text = "Tối ngày hai, một trận bóng đá vẫn diễn ra theo lịch. Và nó nhanh chóng trở thành trận đấu kỳ lạ nhất lịch sử.", big = "", dur = 7.43 },
		{ text = "Một cú phát bóng của thủ môn bình thường bay khoảng sáu, bảy chục mét. Giờ nó bay xa gấp đôi, vượt qua cả chiều dài sân, rơi thẳng ra sau khung thành đối phương.", big = "phát bóng ×2", dur = 10.16 },
		{ text = "Không khí loãng hơn cũng cản bóng ít hơn, nên quả bóng còn bay xa hơn nữa và khó đoán hơn.", big = "", dur = 6.34 },
		{ text = "Các cầu thủ đánh đầu ở độ cao ba mét. Thủ môn bay người như siêu nhân. Nhưng ai chạy nước rút cũng bị nảy lên, trượt chân khi đổi hướng.", big = "", dur = 9.07 },
		{ text = "Đến hiệp hai, cả hai đội đều thở dốc. Không khí loãng như trên núi cao đang bắt đầu rút cạn sức của họ, một dấu hiệu mà ít ai để ý lúc đó.", big = "", dur = 9.89 },
		{ text = "Trọng tài cho dừng trận đấu ở phút sáu mươi. Tỉ số: chín – bảy.", big = "9 – 7", dur = 4.7 },
	},
	{
		{ text = "Người khuân vác ở chợ Long Biên bỗng vác được gấp đôi hàng.", big = "×2", dur = 4.15 },
		{ text = "Ở công trường, cần cẩu nâng được gấp đôi khối lượng. Một xe rùa chở gấp đôi số gạch.", big = "", dur = 5.79 },
		{ text = "Ai đang chuyển nhà thì đúng là trúng số. Tủ lạnh, máy giặt, hai người khiêng lên tầng năm nhẹ tênh.", big = "", dur = 6.34 },
		{ text = "Shipper chở được gấp đôi số hàng trên cùng một chiếc xe. Nhưng như ta vừa thấy, phanh xe thì lại kém đi một nửa…", big = "", dur = 7.43 },
		{ text = "Người già bị đau khớp, người bị đau lưng, lần đầu sau nhiều năm thấy đầu gối nhẹ nhõm. Mỗi bước chân chỉ dồn xuống một nửa sức nặng.", big = "", dur = 8.52 },
		{ text = "Nhưng niềm vui đó không kéo dài. Vì ngày ba… trời bắt đầu mưa.", big = "", dur = 4.43 },
	},
	{
		{ text = "Ngày ba, trời mưa.", big = "NGÀY 3", dur = 1.69 },
		{ text = "Hạt mưa rơi chậm hơn khoảng ba mươi phần trăm. Và chúng có thể to hơn, vì giọt nước không còn bị kéo vỡ nhanh như trước.", big = "rơi chậm ~30%", dur = 7.98 },
		{ text = "Đài phun nước bắn cao gấp đôi. Trẻ con thích lắm.", big = "", dur = 3.61 },
		{ text = "Ô dù cũng trở nên kỳ lạ. Một cơn gió nhẹ là đủ giật chiếc ô khỏi tay bạn, vì chính bạn giờ đã nhẹ hơn, đứng không còn vững như trước. Người ta thấy cả những đứa trẻ bị gió đẩy trượt trên vỉa hè ướt.", big = "", dur = 13.44 },
		{ text = "Nhưng nước cũng thoát chậm hơn. Cống rãnh, mương máng, cả những con sông đều chảy nhờ trọng lực kéo. Theo ước tính, dòng chảy có thể chậm đi khoảng một phần ba. Lượng nước như cũ nhưng chảy chậm hơn, nên mực nước dâng lên.", big = "sông chảy chậm", dur = 13.17 },
		{ text = "Và ở bờ biển, mọi chuyện còn tệ hơn. Thuỷ triều do Mặt Trăng kéo nước lên. Lực kéo của Mặt Trăng vẫn vậy, còn Trái Đất thì giữ nước yếu đi một nửa. Kết quả: thuỷ triều cao gần gấp đôi.", big = "triều ×2", dur = 12.08 },
		{ text = "Ở đồng bằng sông Cửu Long, ở Sài Gòn, nơi mỗi đợt triều cường đã đủ làm ngập phố, nước biển dâng vào, gặp nước sông thoát chậm. Ruộng lúa, vườn cây, những con phố quen thuộc… chìm trong biển nước.", big = "", dur = 11.8 },
		{ text = "Và đó mới chỉ là chuyện dưới mặt đất. Ngày bốn, vấn đề đến từ… vũ trụ.", big = "", dur = 5.24 },
	},
	{
		{ text = "Mỗi vệ tinh quanh Trái Đất đang làm một việc rất tinh tế: nó rơi liên tục, nhưng chạy đủ nhanh để luôn trượt qua mặt đất.", big = "", dur = 7.98 },
		{ text = "Khi lực hút giảm một nửa, tốc độ đó bỗng trở nên quá nhanh. Và đây là một sự trùng hợp đáng sợ: với một nửa trọng lực, tốc độ bay vòng cũ của vệ tinh đúng bằng… tốc độ thoát ly.", big = "v cũ = tốc độ thoát ly", dur = 12.08 },
		{ text = "Nghĩa là gần như mọi vệ tinh, từ GPS, viễn thông, đến Trạm Vũ trụ Quốc tế, bắt đầu từ từ trôi xa khỏi Trái Đất. Chúng không rơi xuống. Chúng bỏ đi.", big = "", dur = 9.62 },
		{ text = "Ngày bốn, Google Maps định vị sai rồi mất hẳn. Tài xế xe công nghệ không tìm được khách. Máy bay, tàu biển mất định vị vệ tinh, phải quay về dùng la bàn và radar. Dự báo thời tiết mù tịt.", big = "MẤT GPS", dur = 12.08 },
		{ text = "May mắn là internet chủ yếu chạy qua cáp quang dưới biển, nên bạn vẫn lướt mạng được.", big = "", dur = 5.52 },
		{ text = "Nhưng ở các trung tâm vũ trụ, người ta lại đang tranh thủ từng giờ. Tốc độ cần để thoát khỏi Trái Đất giảm từ mười một ki-lô-mét mỗi giây xuống chỉ còn khoảng tám. Một tên lửa bình thường giờ có thể chở lên vũ trụ nhiều hàng hơn hẳn. Bảy ngày này là thời cơ phóng tên lửa rẻ nhất lịch sử.", big = "11,2 → 7,9 km/s", dur = 18.09 },
		{ text = "Nhưng nếu vệ tinh còn bỏ đi được… thì thứ lớn hơn nhiều đang treo trên trời kia cũng vậy.", big = "", dur = 6.06 },
	},
	{
		{ text = "Tối ngày bốn, ngoài khơi biển Đông, hàng nghìn tàu cá đang ra khơi.", big = "", dur = 4.43 },
		{ text = "Ngư dân quen đi biển nhờ định vị vệ tinh. Giờ màn hình chỉ báo một dòng: không có tín hiệu.", big = "KHÔNG CÓ TÍN HIỆU", dur = 6.34 },
		{ text = "Những ông lão đi biển cả đời ngước lên trời, tìm sao Bắc Đẩu và nhìn trăng để đoán con nước, như cha ông họ vẫn làm.", big = "", dur = 7.98 },
		{ text = "Nhưng đêm đó, có một người nhận ra một điều kỳ lạ. Mặt Trăng… trông nhỏ hơn hôm qua.", big = "", dur = 5.79 },
		{ text = "Không ai tin ông. Cho đến hai ngày sau.", big = "", dur = 3.06 },
	},
	{
		{ text = "Ngày năm, cơ thể bạn bắt đầu lên tiếng.", big = "NGÀY 5", dur = 3.06 },
		{ text = "Áp suất chỉ còn một nửa, nghĩa là mỗi hơi thở chỉ mang vào khoảng một nửa lượng oxy. Ở ngay mặt đất, bạn đang sống như ở độ cao năm nghìn rưỡi mét, ngang trại nền Everest.", big = "≈ 5.500 m", dur = 10.98 },
		{ text = "Những ngày đầu, cơ thể còn gắng được. Đến ngày năm, sự mệt mỏi tích tụ lại.", big = "", dur = 5.24 },
		{ text = "Không chỉ phổi phải làm việc khác đi. Máu trong cơ thể bị kéo xuống chân nhẹ hơn, nên dồn lên đầu nhiều hơn một chút. Mặt hơi phù, mũi nghẹt, giống như phi hành gia trong những ngày đầu ở vũ trụ.", big = "", dur = 12.35 },
		{ text = "Tim thì đỡ vất vả hơn khi bơm máu lên não. Nằm xuống ngủ, nệm như mềm hơn. Nhưng nhịp thở nhanh vì thiếu oxy khiến nhiều người trằn trọc cả đêm.", big = "", dur = 9.34 },
		{ text = "Leo vài bậc cầu thang là thở dốc. Nhiều người đau đầu, buồn nôn, mất ngủ: đó là say độ cao. Người già, người bệnh tim, phụ nữ mang thai là những người gặp nguy hiểm nhất.", big = "", dur = 10.71 },
		{ text = "Bệnh viện quá tải bình oxy. Người leo núi mất hàng tuần để thích nghi với độ cao này. Ở đây, cả nước phải thích nghi chỉ trong vài ngày.", big = "", dur = 8.8 },
		{ text = "Còn trong bếp, nước sôi ở tám mươi mốt độ: cơm sống, trứng luộc mãi không chín. Mì tôm… cũng vậy. Ai có nồi áp suất bỗng thành người được cả xóm nhờ vả.", big = "81°C", dur = 9.89 },
		{ text = "Nhưng điều đáng sợ nhất của ngày năm lại diễn ra trên trời, và gần như không ai để ý.", big = "", dur = 6.06 },
	},
	{
		{ text = "Ngày sáu. Nhìn lên trời đêm… Mặt Trăng nhỏ hơn.", big = "NGÀY 6", dur = 3.33 },
		{ text = "Mặt Trăng cũng là một vệ tinh. Và như mọi vệ tinh khác, nó đang chạy ở đúng tốc độ thoát ly.", big = "", dur = 6.61 },
		{ text = "Theo tính toán đơn giản, sau bảy ngày nó đã ở xa gần gấp rưỡi bình thường: từ ba trăm tám mươi tư nghìn ki-lô-mét ra khoảng năm trăm sáu mươi tám nghìn.", big = "384.000 → 568.000 km", dur = 9.62 },
		{ text = "Lực kéo thuỷ triều của nó yếu đi rất nhanh. Những con nước lớn mấy ngày trước rút đi, biển lặng hẳn. Và đêm tối hơn bao giờ hết.", big = "", dur = 8.52 },
		{ text = "Người Việt mình gắn với Mặt Trăng hơn mình tưởng. Ông bà mình xem trăng để gieo cấy, ngư dân nhìn trăng để đoán con nước, trẻ con chờ trăng rằm để rước đèn.", big = "", dur = 9.89 },
		{ text = "Đêm ngày sáu, cả triệu người cùng ngẩng lên nhìn một Mặt Trăng đang nhỏ dần, như nhìn một người thân đang đi xa.", big = "", dur = 7.16 },
		{ text = "Nếu trọng lực không quay lại, Mặt Trăng sẽ đi mãi, và loài người sẽ mất nó vĩnh viễn. May mắn thay… ngày mai, trọng lực quay lại.", big = "", dur = 8.25 },
	},
	{
		{ text = "Ngày bảy. Mười giờ sáng. Đúng lúc cả thành phố đã quen với việc nhảy cao…", big = "NGÀY 7", dur = 4.97 },
		{ text = "…trọng lực trở lại.", big = "", dur = 1.69 },
		{ text = "Người đang nhảy rơi xuống mạnh hơn hẳn so với cảm giác của họ. Tai lại ù, áp suất trở về bình thường. Ai cũng thấy người nặng trịch, như vừa vác thêm một người trên vai.", big = "", dur = 10.71 },
		{ text = "Xe cộ trên đường bỗng bám đường trở lại. Những chiếc xe đang trượt dừng khựng. Vòi nước chảy mạnh như cũ. Nồi nước lại sôi ở một trăm độ, và mì tôm cuối cùng cũng chín.", big = "100°C", dur = 10.71 },
		{ text = "Nhưng có những thứ không thể quay lại chỉ bằng một cái bật công tắc.", big = "", dur = 4.7 },
		{ text = "Những vệ tinh đã trôi quá xa thì mất luôn. Cần nhiều năm để phóng lại cả một bầu trời vệ tinh.", big = "", dur = 6.61 },
		{ text = "Còn Mặt Trăng? Nó bị kéo lại, nhưng không về chỗ cũ. Nó rơi vào một quỹ đạo méo: có lúc gần hơn bây giờ nhiều, có lúc xa gấp hơn hai lần.", big = "245.000 – 891.000 km", dur = 9.62 },
	},
	{
		{ text = "Một năm sau, cuộc sống trở lại bình thường. Gần như thế.", big = "1 NĂM SAU", dur = 3.88 },
		{ text = "Từ trăng tròn đến trăng tròn giờ mất khoảng năm mươi bảy ngày, thay vì hai mươi chín rưỡi. Âm lịch đảo lộn. Rằm tháng Tám, Tết Trung Thu… không còn rơi vào ngày bạn quen nữa.", big = "1 tháng âm ≈ 57 ngày", dur = 10.71 },
		{ text = "Mỗi khi Mặt Trăng lướt lại gần, nó to hơn hẳn trên bầu trời, và thuỷ triều có thể cao gấp nhiều lần hôm nay. Mỗi khi nó ra xa, nó chỉ còn bằng một nửa, và đêm tối mịt.", big = "", dur = 11.53 },
		{ text = "Nhật thực toàn phần chỉ còn xảy ra khi Mặt Trăng ở gần. Khi nó ở xa, nó quá nhỏ để che kín Mặt Trời, chỉ còn những vòng nhật thực hình khuyên.", big = "", dur = 9.62 },
		{ text = "Các nhà khoa học sẽ mất nhiều năm để tính lại lịch thuỷ triều cho mọi cảng biển trên thế giới. Ngư dân phải học lại biển, như học lại từ đầu.", big = "", dur = 9.34 },
		{ text = "Bảy ngày trọng lực giảm một nửa… để lại dấu vết trên bầu trời có thể kéo dài hàng triệu năm.", big = "", dur = 6.34 },
		{ text = "Nhớ câu đố đầu video không? Thứ gây thiệt hại lớn nhất không phải giao thông, cũng không phải thời tiết. Mà là bầu trời: vệ tinh bỏ đi, và Mặt Trăng không bao giờ trở về chỗ cũ. Bạn đoán đúng chứ?", big = "", dur = 12.35 },
	},
	{
		{ text = "Nếu được sống một ngày trọng lực giảm một nửa, bạn sẽ làm gì? Nhảy qua nóc nhà, úp rổ lần đầu trong đời, hay chuyển nhà miễn phí cho cả xóm? Bình luận cho mình biết nhé.", big = "👇 BÌNH LUẬN", dur = 10.98 },
		{ text = "Video tiếp theo: nếu Trái Đất ngừng quay một giây? Bấm đăng ký để không bỏ lỡ.", big = "ĐĂNG KÝ", dur = 5.24 },
	},
}

function VD.run(Kit)
	Video.CAST_OVERRIDE = CAST
	local ctx = Video.build(Kit)
	local P, A = ctx.P, ctx.A
	local box, ball, cyl, weld, sign, light = Kit.box, Kit.ball, Kit.cyl, Kit.weld, Kit.sign, Kit.light
	local rad = math.rad
	local fx = Kit.fx
	local Minh, Ban, Linh, Tuan = A.Minh, A.Ban, A.Linh, A.Tuan
	local everyone = { Ban, A.KhachA, A.KhachB, A.KhachC, A.KhachD, Linh, Tuan }

	------------------------------------------------------------------ LỜI KỂ
	local function L(ch, i, action)
		local d = NARR[ch][i]
		if d.big ~= "" then
			task.delay(0.5, fx, "big", d.big, math.min(d.dur, 3))
		end
		ctx.beat(d.text, d.dur, action)
	end
	local function chapterCard(text)
		fx("line", "", "")
		fx("caption", text)
	end

	------------------------------------------------------------------ CÔNG CỤ CHUNG
	local function modelOf(name, parts, primary)
		local m = Instance.new("Model")
		m.Name = name
		for _, p in ipairs(parts) do
			p.Parent = m
			if p ~= primary then
				p.Anchored = false
				p.CanCollide = false
				weld(primary, p)
			end
		end
		m.PrimaryPart = primary
		m.Parent = Kit.SET
		return m
	end
	-- nhảy theo parabol từ vị trí hiện tại tới điểm đích (mặt đất)
	local function hop(a, to, height, dur)
		local start = a.model:GetPivot()
		local goal = Vector3.new(to.X, to.Y + a.standY, to.Z)
		local t0 = os.clock()
		Kit.pose(a, "cheer", 0.12, false)
		while true do
			local t = (os.clock() - t0) / dur
			if t >= 1 then
				break
			end
			local p = start.Position:Lerp(goal, t) + Vector3.new(0, 4 * height * t * (1 - t), 0)
			a.model:PivotTo(CFrame.new(p) * start.Rotation)
			RunService.Heartbeat:Wait()
		end
		a.model:PivotTo(CFrame.new(goal) * start.Rotation)
		Kit.pose(a, "rest", 0.15, false)
	end
	local function hopModel(m, to, height, dur)
		local start = m:GetPivot()
		local t0 = os.clock()
		while true do
			local t = (os.clock() - t0) / dur
			if t >= 1 then
				break
			end
			m:PivotTo(CFrame.new(start.Position:Lerp(to, t) + Vector3.new(0, 4 * height * t * (1 - t), 0)) * start.Rotation)
			RunService.Heartbeat:Wait()
		end
		m:PivotTo(CFrame.new(to) * start.Rotation)
	end
	local function sky()
		local s = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
		s.Parent = Lighting
		return s
	end
	local function lookAtMoon(from, mm, time)
		local dir = Lighting:GetMoonDirection()
		Kit.cam({ pos = from, look = from + dir * 200, mm = mm or 50, time = time or 0, occlude = false, drift = 0 })
	end
	local function particles(parent, props)
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		for k, v in pairs(props) do
			e[k] = v
		end
		e.Parent = parent
		return e
	end
	local function billboard(part, text, color, size)
		local g = Instance.new("BillboardGui")
		g.Size = size or UDim2.fromOffset(160, 56)
		g.StudsOffset = Vector3.new(0, 3, 0)
		g.AlwaysOnTop = true
		g.Parent = part
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundColor3 = color or Color3.fromRGB(200, 40, 40)
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Font = Enum.Font.GothamBlack
		t.TextScaled = true
		t.Text = text
		t.Parent = g
		Instance.new("UICorner", t).CornerRadius = UDim.new(0, 12)
		return g, t
	end
	local function showOnly(list)
		local keep = {}
		for _, a in ipairs(list) do
			keep[a] = true
		end
		for _, a in pairs(A) do
			if not keep[a] then
				Kit.hide(a)
			end
			Kit.resetPose(a)
			a.face:SetAttribute("Talking", false)
		end
	end

	------------------------------------------------------------------ ĐẠO CỤ: CON VẬT, XE, MÁY BAY, TÊN LỬA, VỆ TINH
	local function makeCat(cf, col)
		col = col or "#e2a35a"
		local body = box("CatBody", Vector3.new(1.8, 0.9, 0.9), cf * CFrame.new(0, 0.9, 0), col)
		local parts = {
			ball("CatHead", 0.9, cf * CFrame.new(1.05, 1.35, 0), col),
			Kit.box("EarL", Vector3.new(0.18, 0.35, 0.25), cf * CFrame.new(1.05, 1.85, 0.25), col),
			Kit.box("EarR", Vector3.new(0.18, 0.35, 0.25), cf * CFrame.new(1.05, 1.85, -0.25), col),
			Kit.box("Tail", Vector3.new(0.15, 1.2, 0.15), cf * CFrame.new(-1.0, 1.4, 0) * CFrame.Angles(0, 0, rad(-25)), col),
			ball("EyeL", 0.16, cf * CFrame.new(1.45, 1.45, 0.2), "#1a1a1a"),
			ball("EyeR", 0.16, cf * CFrame.new(1.45, 1.45, -0.2), "#1a1a1a"),
		}
		for _, x in ipairs({ -0.6, 0.6 }) do
			for _, z in ipairs({ -0.3, 0.3 }) do
				table.insert(parts, Kit.box("Leg", Vector3.new(0.22, 0.6, 0.22), cf * CFrame.new(x, 0.3, z), col))
			end
		end
		table.insert(parts, 1, body)
		return modelOf("Cat", parts, body)
	end
	local function makeDog(cf)
		local col = "#b8864e"
		local body = box("DogBody", Vector3.new(2.4, 1.2, 1.1), cf * CFrame.new(0, 1.4, 0), col)
		local parts = {
			body,
			Kit.box("DogHead", Vector3.new(1, 0.9, 0.9), cf * CFrame.new(1.5, 2.1, 0), col),
			Kit.box("Snout", Vector3.new(0.5, 0.45, 0.55), cf * CFrame.new(2.1, 1.95, 0), "#d8b080"),
			ball("Nose", 0.22, cf * CFrame.new(2.37, 2.05, 0), "#1a1a1a"),
			Kit.box("EarL", Vector3.new(0.3, 0.6, 0.15), cf * CFrame.new(1.4, 2.3, 0.5), "#8a5a2a"),
			Kit.box("EarR", Vector3.new(0.3, 0.6, 0.15), cf * CFrame.new(1.4, 2.3, -0.5), "#8a5a2a"),
			Kit.box("Tail", Vector3.new(0.2, 0.9, 0.2), cf * CFrame.new(-1.35, 2.1, 0) * CFrame.Angles(0, 0, rad(-40)), col),
		}
		for _, x in ipairs({ -0.85, 0.85 }) do
			for _, z in ipairs({ -0.35, 0.35 }) do
				table.insert(parts, Kit.box("Leg", Vector3.new(0.3, 0.9, 0.3), cf * CFrame.new(x, 0.45, z), col))
			end
		end
		return modelOf("Dog", parts, body)
	end
	local function makeBird(cf, col)
		local body = ball("Bird", 0.6, cf, col or "#4a4a52")
		return modelOf("Bird", {
			body,
			Kit.box("WingL", Vector3.new(0.35, 0.06, 0.9), cf * CFrame.new(0, 0.05, 0.6) * CFrame.Angles(rad(-15), 0, 0), col or "#4a4a52"),
			Kit.box("WingR", Vector3.new(0.35, 0.06, 0.9), cf * CFrame.new(0, 0.05, -0.6) * CFrame.Angles(rad(15), 0, 0), col or "#4a4a52"),
			Kit.box("Beak", Vector3.new(0.25, 0.1, 0.1), cf * CFrame.new(0.38, 0, 0), "#e8a33a"),
		}, body)
	end
	local function makeMoto(cf, col)
		local body = box("MotoBody", Vector3.new(3, 1.1, 0.7), cf * CFrame.new(0, 1.5, 0), col or "#c8322f", Enum.Material.Metal)
		local parts = {
			body,
			Kit.box("Seat", Vector3.new(1.6, 0.35, 0.75), cf * CFrame.new(-0.3, 2.2, 0), "#1d1d1d"),
			Kit.box("Front", Vector3.new(0.6, 1.6, 0.8), cf * CFrame.new(1.4, 2, 0) * CFrame.Angles(0, 0, rad(-15)), col or "#c8322f", Enum.Material.Metal),
			Kit.box("Bar", Vector3.new(0.15, 0.15, 1.6), cf * CFrame.new(1.6, 2.9, 0), "#2b2b2b", Enum.Material.Metal),
			ball("Light", 0.4, cf * CFrame.new(1.8, 2.6, 0), "#fff2c0", Enum.Material.Neon),
		}
		for _, wx in ipairs({ -1.3, 1.5 }) do
			local w = Kit.box("Wheel", Vector3.new(0.35, 1.3, 1.3), cf * CFrame.new(wx, 0.65, 0) * CFrame.Angles(0, rad(90), 0), "#1a1a1a")
			w.Shape = Enum.PartType.Cylinder
			table.insert(parts, w)
		end
		return modelOf("Moto", parts, body)
	end
	local function makePlane(cf)
		local body = Kit.box("Fuselage", Vector3.new(40, 5, 5), cf * CFrame.new(0, 5, 0), "#f2f2f2")
		body.Shape = Enum.PartType.Cylinder
		local parts = {
			body,
			ball("Nose", 5, cf * CFrame.new(20, 5, 0), "#f2f2f2"),
			Kit.box("Wing", Vector3.new(7, 0.5, 38), cf * CFrame.new(2, 4, 0), "#dfe3e8"),
			Kit.box("TailWing", Vector3.new(4, 0.4, 14), cf * CFrame.new(-18, 6, 0), "#dfe3e8"),
			Kit.box("Fin", Vector3.new(5, 7, 0.4), cf * CFrame.new(-18, 9.5, 0), "#c8322f"),
			Kit.box("Stripe", Vector3.new(36, 0.8, 5.1), cf * CFrame.new(0, 5.2, 0), "#2f6ab0"),
			Kit.box("Windows", Vector3.new(30, 0.6, 5.12), cf * CFrame.new(1, 6.2, 0), "#1f2a36"),
		}
		for _, z in ipairs({ -8, 8 }) do
			local e = Kit.box("Engine", Vector3.new(5, 2, 2), cf * CFrame.new(3, 2.8, z), "#9aa3a8", Enum.Material.Metal)
			e.Shape = Enum.PartType.Cylinder
			table.insert(parts, e)
		end
		for _, p in ipairs({ { 12, 0 }, { -2, -3 }, { -2, 3 } }) do
			table.insert(parts, Kit.box("Gear", Vector3.new(0.6, 2.4, 0.6), cf * CFrame.new(p[1], 1.2, p[2]), "#2b2b2b"))
		end
		return modelOf("Plane", parts, body)
	end
	local function makeRocket(cf)
		local body = cyl("Stage1", 30, 4, cf * CFrame.new(0, 15, 0), "#f2f2f2", Enum.Material.Metal)
		local parts = {
			body,
			cyl("Stage2", 14, 3.4, cf * CFrame.new(0, 37, 0), "#f2f2f2", Enum.Material.Metal),
			ball("NoseCone", 3.4, cf * CFrame.new(0, 44.5, 0), "#e8e8e8", Enum.Material.Metal),
			cyl("Band", 1, 4.1, cf * CFrame.new(0, 26, 0), "#1a1a1a"),
			Kit.box("Flag", Vector3.new(0.1, 3, 2), cf * CFrame.new(2.02, 20, 0), "#c8322f"),
		}
		for k = 0, 3 do
			table.insert(parts, Kit.box("Fin", Vector3.new(0.3, 5, 2.5), cf * CFrame.Angles(0, rad(k * 90), 0) * CFrame.new(0, 2.5, 2.8), "#2b2b2b"))
		end
		local m = modelOf("Rocket", parts, body)
		local fire = particles(body, {
			Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 80, 20)),
			LightEmission = 1,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0.5) }),
			Speed = NumberRange.new(40, 60),
			Lifetime = NumberRange.new(0.3, 0.5),
			Rate = 0,
			EmissionDirection = Enum.NormalId.Left,
		})
		local smoke = particles(body, {
			Texture = "rbxasset://textures/particles/smoke_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(230, 230, 230)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 14) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
			Speed = NumberRange.new(10, 20),
			SpreadAngle = Vector2.new(40, 40),
			Lifetime = NumberRange.new(2, 4),
			Rate = 0,
			EmissionDirection = Enum.NormalId.Left,
		})
		return m, fire, smoke
	end
	local function makeSatellite(cf, scale)
		scale = scale or 1
		local core = Kit.box("SatCore", Vector3.new(2, 2, 2) * scale, cf, "#d4af37", Enum.Material.Foil)
		return modelOf("Satellite", {
			core,
			Kit.box("PanelL", Vector3.new(0.1, 1.6, 4) * scale, cf * CFrame.new(0, 0, 3.2 * scale), "#2a3f8f", Enum.Material.Glass),
			Kit.box("PanelR", Vector3.new(0.1, 1.6, 4) * scale, cf * CFrame.new(0, 0, -3.2 * scale), "#2a3f8f", Enum.Material.Glass),
			Kit.box("Dish", Vector3.new(0.3, 1.2, 1.2) * scale, cf * CFrame.new(1.2 * scale, 0, 0), "#e8e8e8"),
		}, core)
	end

	------------------------------------------------------------------ BỐI CẢNH (dựng khi cần)
	local SETS, built = {}, {}
	local function need(name)
		if not built[name] then
			built[name] = SETS[name]()
		end
		return built[name]
	end

	-- PHÒNG Ở CỦA MINH: cân, vòi nước, bếp, tủ lạnh, con mèo
	SETS.room = function()
		local R = Kit.origin(Vector3.new(0, 0, -1500))
		box("Floor", Vector3.new(22, 1, 18), R(0, -0.5, 0), "#cfc6b4", Enum.Material.Marble)
		box("Ceil", Vector3.new(22, 1, 18), R(0, 10.5, 0), "#efebe0")
		box("WallBack", Vector3.new(22, 11, 1), R(0, 5, 9), "#e2dcc3", Enum.Material.Plaster)
		box("WallL", Vector3.new(1, 11, 18), R(-11, 5, 0), "#e2dcc3", Enum.Material.Plaster)
		box("WallR", Vector3.new(1, 11, 18), R(11, 5, 0), "#e2dcc3", Enum.Material.Plaster)
		box("WallFront", Vector3.new(22, 11, 1), R(0, 5, -9), "#e2dcc3", Enum.Material.Plaster)
		box("Window", Vector3.new(6, 4, 0.2), R(-2, 5.5, 8.45), "#cfe6ee", Enum.Material.Glass, { Transparency = 0.4 })
		local sunSrc = box("Sun", Vector3.new(1, 1, 1), CFrame.lookAt(R(-6, 14, 24), R(0, 0, 0)), "#ffffff", nil, { Transparency = 1, CanCollide = false, CastShadow = false })
		light("SpotLight", sunSrc, { Face = Enum.NormalId.Front, Angle = 50, Range = 40, Brightness = 5, Color = Color3.fromRGB(255, 226, 180), Shadows = true })
		box("BedFrame", Vector3.new(6, 1.2, 9), R(-7, 0.6, 3.5), "#6b4a32", Enum.Material.Wood)
		box("Mattress", Vector3.new(5.8, 0.6, 8.8), R(-7, 1.5, 3.5), "#e8e2d4", Enum.Material.Fabric)
		box("Blanket", Vector3.new(5.9, 0.3, 4), R(-7, 1.9, 2), "#7d93b0", Enum.Material.Fabric)
		box("Fridge", Vector3.new(3, 6.5, 3), R(8.8, 3.25, 6.5), "#e8ecef", Enum.Material.Metal)
		box("FridgeLine", Vector3.new(0.05, 0.1, 3), R(7.27, 4.4, 6.5), "#9aa3a8")
		box("Wardrobe", Vector3.new(4, 8.5, 2.2), R(4, 4.25, 7.8), "#8b6a4a", Enum.Material.Wood)
		-- cân sức khoẻ
		local scale = box("Scale", Vector3.new(1.8, 0.25, 1.8), R(0, 0.125, -2), "#2b2f36", Enum.Material.Glass)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Top
		sg.CanvasSize = Vector2.new(200, 200)
		sg.LightInfluence = 0
		sg.Parent = scale
		local scaleText = Instance.new("TextLabel")
		scaleText.Size = UDim2.fromScale(1, 0.5)
		scaleText.Position = UDim2.fromScale(0, 0.25)
		scaleText.BackgroundTransparency = 1
		scaleText.TextColor3 = Color3.fromRGB(120, 255, 160)
		scaleText.Font = Enum.Font.Code
		scaleText.TextScaled = true
		scaleText.Text = "0.0"
		scaleText.Parent = sg
		-- bồn rửa + vòi
		box("Sink", Vector3.new(3, 3, 2), R(-9, 1.5, -6), "#f2f2f2", Enum.Material.Marble)
		local tap = box("Tap", Vector3.new(0.3, 0.3, 1), R(-9, 4.2, -6.6), "#c8ccd0", Enum.Material.Metal)
		local water = particles(tap, {
			Color = ColorSequence.new(Color3.fromRGB(170, 210, 255)),
			Size = NumberSequence.new(0.12),
			Transparency = NumberSequence.new(0.3),
			Speed = NumberRange.new(10),
			Acceleration = Vector3.new(0, -60, 0),
			Lifetime = NumberRange.new(0.18),
			Rate = 0,
			EmissionDirection = Enum.NormalId.Bottom,
		})
		-- bếp + nồi
		box("Counter", Vector3.new(4, 3.2, 2.4), R(8.8, 1.6, -4), "#a99f8d", Enum.Material.Wood)
		local pot = cyl("Pot", 1.4, 2, R(8.8, 3.9, -4), "#b8bec2", Enum.Material.Metal)
		particles(pot, {
			Texture = "rbxasset://textures/particles/smoke_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(240, 240, 240)),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) }),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 2) }),
			Speed = NumberRange.new(2, 3),
			Lifetime = NumberRange.new(1.5, 2),
			Rate = 12,
		})
		local potLabel = billboard(pot, "81°C")
		potLabel.Enabled = false
		local cat = makeCat(CFrame.new(R(5, 0, 2)) * CFrame.Angles(0, rad(-90), 0))
		return { R = R, scaleText = scaleText, water = water, potLabel = potLabel, cat = cat }
	end

	-- KHU TẬP THỂ: cầu thang ngoài trời 5 tầng
	SETS.stairs = function()
		local S = Kit.origin(Vector3.new(300, 0, -1500))
		Kit.surround(S(0, 0, 0), 90, { seed = 21 })
		box("Ground", Vector3.new(80, 1, 50), S(0, -0.5, 0), "#9e9484", Enum.Material.Concrete)
		box("Block", Vector3.new(60, 28, 14), S(0, 14, 14), "#d8c9a8", Enum.Material.Plaster)
		for fl = 1, 5 do
			local y = fl * 5
			box("Corridor", Vector3.new(60, 0.5, 3), S(0, y - 0.25, 5.5), "#bfb3a0", Enum.Material.Concrete)
			box("Rail", Vector3.new(60, 1.2, 0.15), S(0, y + 0.6, 4.1), "#3a5a4a", Enum.Material.Metal)
			for k = -2, 2 do
				box("Door", Vector3.new(3, 4, 0.2), S(k * 11, y + 2, 6.95), "#4d6b5a", Enum.Material.Wood)
				box("Laundry", Vector3.new(1, 1.2, 0.05), S(k * 11 + 3, y + 3.2, 4.2), ({ "#d64545", "#e8e8e8", "#4a78b8" })[(k + fl) % 3 + 1], Enum.Material.Fabric)
			end
		end
		-- cầu thang thẳng từ tầng 5 xuống đất (40 bậc)
		for i = 0, 39 do
			box("Step", Vector3.new(1, 0.5, 3), S(-20 + i, 25 - i * 0.625 - 0.3, 1.5), "#a9a294", Enum.Material.Concrete)
		end
		box("StairRail", Vector3.new(42, 0.2, 0.2), CFrame.new(S(0, 14, 0)) * CFrame.Angles(0, 0, rad(-32)), "#3a5a4a", Enum.Material.Metal)
		return { S = S }
	end

	-- QUÁN PHỞ + GÁNH XÔI (trên vỉa hè quảng trường)
	SETS.pho = function()
		local T = P(-30, 0, -55)
		box("PhoTable", Vector3.new(4, 0.25, 2.4), T + Vector3.new(0, 2.6, 0), "#d8d2c4", Enum.Material.Marble)
		box("PhoLeg", Vector3.new(0.3, 2.5, 0.3), T + Vector3.new(0, 1.25, 0), "#2b2b2b", Enum.Material.Metal)
		for _, x in ipairs({ -1.6, 1.6 }) do
			box("Stool", Vector3.new(1.1, 1.4, 1.1), T + Vector3.new(x, 0.7, 1.9), "#2f6ab0")
		end
		local bowlBase = cyl("Bowl", 0.6, 1.4, T + Vector3.new(0, 3.05, 0), "#f2efe6")
		local soup = cyl("Soup", 0.05, 1.25, T + Vector3.new(0, 3.38, 0), "#c9893a", Enum.Material.Glass, { Transparency = 0.1, Reflectance = 0.2 })
		cyl("Noodle", 0.06, 0.9, T + Vector3.new(0, 3.4, 0), "#f2ead2", Enum.Material.Fabric)
		particles(bowlBase, {
			Texture = "rbxasset://textures/particles/smoke_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(245, 245, 245)),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) }),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1.2) }),
			Speed = NumberRange.new(1, 2),
			Lifetime = NumberRange.new(1.5),
			Rate = 8,
		})
		local sgn = box("PhoSign", Vector3.new(6, 1.4, 0.3), P(-30, 6.2, -59.6), "#c8322f")
		sign(sgn, "PHỞ GIA TRUYỀN", Enum.NormalId.Back, { color = Color3.fromRGB(255, 236, 170), font = Enum.Font.GothamBlack, glow = true })
		-- đòn gánh xôi
		local pole = box("Pole", Vector3.new(0.2, 0.2, 5), P(0, 0, 0), "#b08a5a", Enum.Material.Wood)
		local gparts = { pole }
		for _, z in ipairs({ -2.3, 2.3 }) do
			table.insert(gparts, cyl("Basket", 1.2, 1.8, CFrame.new(P(0, -2.6, z)), "#c8a46a", Enum.Material.Fabric))
			table.insert(gparts, ball("Xoi", 1.6, CFrame.new(P(0, -1.9, z)), "#f2e28a"))
			table.insert(gparts, Kit.box("Rope", Vector3.new(0.05, 2, 0.05), CFrame.new(P(0, -1, z)), "#5a4a3a"))
		end
		local ganh = modelOf("Ganh", gparts, pole)
		local moto = makeMoto(CFrame.new(P(-24, 0, -53)) * CFrame.Angles(0, rad(90), 0), "#2a4d8f")
		return { T = T, bowl = { bowlBase, soup }, ganh = ganh, moto = moto }
	end

	-- SÂN VẬN ĐỘNG
	SETS.stadium = function()
		local D = Kit.origin(Vector3.new(700, 0, -1500))
		for i = -5, 4 do
			box("Pitch", Vector3.new(10, 1, 66), D(i * 10 + 5, -0.5, 0), i % 2 == 0 and "#3f8a3a" or "#4a9a42", Enum.Material.Grass)
		end
		local function line(sz, pos)
			box("Line", sz, pos, "#f2f2f2", nil, { CanCollide = false })
		end
		line(Vector3.new(100, 0.05, 0.4), D(0, 0.03, 32))
		line(Vector3.new(100, 0.05, 0.4), D(0, 0.03, -32))
		line(Vector3.new(0.4, 0.05, 64), D(50, 0.03, 0))
		line(Vector3.new(0.4, 0.05, 64), D(-50, 0.03, 0))
		line(Vector3.new(0.4, 0.05, 64), D(0, 0.03, 0))
		for k = 0, 23 do
			local a = rad(k * 15)
			line(Vector3.new(0.4, 0.05, 2.6), CFrame.new(D(math.cos(a) * 9, 0.03, math.sin(a) * 9)) * CFrame.Angles(0, -a, 0))
		end
		for _, sx in ipairs({ -1, 1 }) do
			line(Vector3.new(0.4, 0.05, 40), D(sx * 34, 0.03, 0))
			line(Vector3.new(16, 0.05, 0.4), D(sx * 42, 0.03, 20))
			line(Vector3.new(16, 0.05, 0.4), D(sx * 42, 0.03, -20))
			-- khung thành
			box("Post", Vector3.new(0.4, 8, 0.4), D(sx * 50, 4, 7.5), "#ffffff")
			box("Post", Vector3.new(0.4, 8, 0.4), D(sx * 50, 4, -7.5), "#ffffff")
			box("Bar", Vector3.new(0.4, 0.4, 15.4), D(sx * 50, 8, 0), "#ffffff")
			box("Net", Vector3.new(4, 8, 15), D(sx * 52, 4, 0), "#ffffff", Enum.Material.Fabric, { Transparency = 0.7, CanCollide = false })
		end
		-- khán đài + khán giả
		local rng = Random.new(9)
		local fans = { "#c8322f", "#f2f2f2", "#e8c547", "#2f6ab0", "#c8322f", "#1d1d1d" }
		for _, sz in ipairs({ -1, 1 }) do
			for row = 0, 7 do
				box("Stand", Vector3.new(120, 1.5, 3), D(0, row * 1.5 + 0.75, sz * (40 + row * 3)), "#7a7a80", Enum.Material.Concrete)
				for k = 0, 39 do
					box("Fan", Vector3.new(1, 1.6, 0.8), D(-58 + k * 3 + rng:NextNumber(-0.5, 0.5), row * 1.5 + 2.3, sz * (40 + row * 3)), fans[rng:NextInteger(1, #fans)], nil, { CanCollide = false })
				end
			end
		end
		-- đèn pha
		for _, p in ipairs({ { -60, -50 }, { 60, -50 }, { -60, 50 }, { 60, 50 } }) do
			box("Tower", Vector3.new(1.5, 40, 1.5), D(p[1], 20, p[2]), "#5a5a60", Enum.Material.Metal)
			local head = box("Flood", Vector3.new(8, 4, 1), CFrame.lookAt(D(p[1], 40, p[2]), D(0, 0, 0)), "#fffbe8", Enum.Material.Neon)
			light("SpotLight", head, { Face = Enum.NormalId.Front, Angle = 60, Range = 120, Brightness = 3, Color = Color3.fromRGB(255, 250, 235), Shadows = true })
		end
		local board = box("Scoreboard", Vector3.new(24, 8, 1), D(0, 26, 66), "#111111")
		local _, scoreText = billboard(board, "0 – 0", Color3.fromRGB(10, 10, 10), UDim2.fromOffset(260, 90))
		return { D = D, scoreText = scoreText }
	end

	-- CHỢ + CÔNG TRƯỜNG
	SETS.market = function()
		local K = Kit.origin(Vector3.new(0, 0, -2000))
		Kit.surround(K(0, 0, 0), 110, { seed = 33 })
		box("Ground", Vector3.new(120, 1, 70), K(0, -0.5, 0), "#9e9484", Enum.Material.Concrete)
		local produce = { "#e2652b", "#7aa83a", "#e8c547", "#c8322f", "#6a3a8a" }
		for i = 0, 5 do
			local x = -40 + i * 9
			box("Stall", Vector3.new(6, 2.6, 3), K(x, 1.3, -14), "#8b6a4a", Enum.Material.Wood)
			box("Tarp", Vector3.new(7, 0.2, 4), CFrame.new(K(x, 6, -14)) * CFrame.Angles(rad(-8), 0, 0), i % 2 == 0 and "#2f6ab0" or "#c8322f", Enum.Material.Fabric)
			box("TarpPole", Vector3.new(0.2, 6, 0.2), K(x - 3, 3, -12.5), "#cccccc", Enum.Material.Metal)
			for k = 0, 9 do
				ball("Fruit", 0.7, K(x - 2.4 + (k % 5) * 1.2, 2.95, -14.5 + math.floor(k / 5)), produce[(i + k) % #produce + 1])
			end
		end
		local sacks = {}
		for k = 0, 5 do
			table.insert(sacks, box("Sack", Vector3.new(2, 1.2, 1.4), K(-46, 0.6 + k * 1.2, -4), "#d8c8a0", Enum.Material.Fabric))
		end
		-- khung nhà đang xây + cần cẩu tháp
		for x = 0, 3 do
			for z = 0, 2 do
				box("Column", Vector3.new(1, 24, 1), K(14 + x * 8, 12, 6 + z * 8), "#a9a294", Enum.Material.Concrete)
			end
		end
		for fl = 1, 3 do
			box("Slab", Vector3.new(26, 0.8, 18), K(26, fl * 8, 14), "#bfb8a8", Enum.Material.Concrete)
		end
		box("Mast", Vector3.new(2.4, 60, 2.4), K(50, 30, 30), "#e8c547", Enum.Material.DiamondPlate)
		local jib = box("Jib", Vector3.new(50, 2, 2), K(35, 60, 30), "#e8c547", Enum.Material.DiamondPlate)
		box("Counterweight", Vector3.new(6, 4, 4), K(62, 58, 30), "#5a5a60", Enum.Material.Concrete)
		local hook = box("Hook", Vector3.new(0.8, 1.2, 0.8), K(20, 20, 30), "#2b2b2b", Enum.Material.Metal)
		local cable = box("Cable", Vector3.new(0.1, 40, 0.1), K(20, 40, 30), "#111111")
		local pallet = box("Pallet", Vector3.new(4, 0.4, 4), K(20, 17, 30), "#8b6a4a", Enum.Material.Wood)
		local load = { pallet }
		for k = 0, 7 do
			table.insert(load, Kit.box("Bricks", Vector3.new(1.8, 0.9, 1.8), K(19 + (k % 2) * 2, 17.65 + math.floor(k / 4) * 0.9, 29 + (math.floor(k / 2) % 2) * 2), "#b85a3a", Enum.Material.Brick))
		end
		table.insert(load, hook)
		table.insert(load, cable)
		local crane = modelOf("CraneLoad", load, pallet)
		crane:PivotTo(CFrame.new(K(20, 0.2, 30)))
		local fridge = box("Fridge", Vector3.new(3, 6.5, 3), K(-10, 3.25, 14), "#e8ecef", Enum.Material.Metal)
		local van = ctx.car("MoveVan", CFrame.new(K(-28, 0, 16)), "#f2f2f2")
		local moto = makeMoto(CFrame.new(K(-60, 0, 26)) * CFrame.Angles(0, 0, 0), "#1b7a3e")
		local stack = {}
		for k = 0, 5 do
			table.insert(stack, Kit.box("Parcel", Vector3.new(1.6, 1.1, 1.6), moto:GetPivot() * CFrame.new(-1.2, 2.9 + k * 1.1, 0), ({ "#c8a46a", "#d8b880" })[k % 2 + 1], Enum.Material.Cardboard))
		end
		for _, b in ipairs(stack) do
			b.Anchored = false
			b.CanCollide = false
			b.Parent = moto
			weld(moto.PrimaryPart, b)
		end
		return { K = K, sacks = sacks, crane = crane, fridge = fridge, moto = moto }
	end

	-- PHỐ VEN SÔNG MIỀN TÂY + RUỘNG LÚA (ngập)
	SETS.flood = function()
		local W = Kit.origin(Vector3.new(1100, 0, -1500))
		Kit.surround(W(0, 0, 0), 120, { seed = 44, ground = "#5f8f42" })
		box("Ground", Vector3.new(160, 1, 120), W(0, -0.5, 0), "#6f8a4a", Enum.Material.Grass)
		box("Road", Vector3.new(160, 0.3, 10), W(0, 0.15, 0), "#5a5a5e", Enum.Material.Asphalt)
		local cols = { "#e3c06a", "#b9cdd6", "#e0a8a0", "#cfd6b0", "#f0e0c0" }
		for i = 0, 9 do
			local x = -60 + i * 13
			box("House", Vector3.new(9, 9, 9), W(x, 4.5, -11), cols[i % #cols + 1], Enum.Material.Plaster)
			box("Roof", Vector3.new(10, 0.6, 10), W(x, 9.3, -11), "#a8553a", Enum.Material.ClayRoofTiles)
			box("Door", Vector3.new(3, 5, 0.2), W(x, 2.5, -6.45), "#5a4430", Enum.Material.Wood)
		end
		-- ruộng lúa
		for i = 0, 7 do
			for j = 0, 2 do
				box("Paddy", Vector3.new(16, 0.6, 12), W(-60 + i * 17, 0.3, 14 + j * 13), (i + j) % 2 == 0 and "#7ab83a" or "#8ac84a", Enum.Material.Grass)
			end
		end
		-- dừa
		for k = 0, 7 do
			local x = -64 + k * 18
			box("PalmTrunk", Vector3.new(0.8, 14, 0.8), CFrame.new(W(x, 7, 7)) * CFrame.Angles(0, 0, rad(6)), "#8a6a4a", Enum.Material.Wood)
			for f = 0, 5 do
				box("Frond", Vector3.new(6, 0.2, 1.2), CFrame.new(W(x + 0.7, 14, 7)) * CFrame.Angles(0, rad(f * 60), rad(-20)) * CFrame.new(3, 0, 0), "#3f7a32", Enum.Material.Grass)
			end
		end
		-- sông và bờ kè
		box("River", Vector3.new(160, 0.4, 30), W(0, -0.6, 60), "#4a7a8a", Enum.Material.Glass, { Transparency = 0.2, Reflectance = 0.3 })
		box("Embankment", Vector3.new(160, 1.5, 2), W(0, 0.75, 44), "#a9a294", Enum.Material.Concrete)
		local flood = box("FloodWater", Vector3.new(160, 1, 120), W(0, -1, 0), "#5a7a6a", Enum.Material.Glass, { Transparency = 0.25, Reflectance = 0.25, CanCollide = false })
		local umbrella = box("Umbrella", Vector3.new(4, 0.3, 4), W(0, 7, 2), "#c8322f", Enum.Material.Fabric)
		return { W = W, flood = flood, umbrella = umbrella }
	end

	-- SÂN BAY + BỆ PHÓNG TÊN LỬA
	SETS.airport = function()
		local Y = Kit.origin(Vector3.new(1500, 0, -1500))
		Kit.surround(Y(0, 0, 0), 220, { seed = 55, ground = "#7a8a5a" })
		box("Runway", Vector3.new(320, 0.3, 26), Y(0, 0.15, 0), "#4a4a4e", Enum.Material.Asphalt)
		for x = -150, 150, 20 do
			box("Mark", Vector3.new(10, 0.05, 0.8), Y(x, 0.32, 0), "#f2f2f2", nil, { CanCollide = false })
		end
		box("Grass", Vector3.new(340, 0.2, 200), Y(0, -0.1, 40), "#6a9a4a", Enum.Material.Grass)
		box("Tower", Vector3.new(6, 30, 6), Y(40, 15, -40), "#d8d2c4", Enum.Material.Concrete)
		box("TowerTop", Vector3.new(10, 5, 10), Y(40, 32, -40), "#3d5570", Enum.Material.Glass, { Transparency = 0.2 })
		local plane = makePlane(CFrame.new(Y(-130, 0.3, 0)))
		box("Pad", Vector3.new(24, 2, 24), Y(60, 1, 90), "#8a8a8a", Enum.Material.Concrete)
		box("LaunchTower", Vector3.new(3, 50, 3), Y(66, 25, 90), "#c8322f", Enum.Material.DiamondPlate)
		local rocket, fire, smoke = makeRocket(CFrame.new(Y(60, 2, 90)))
		return { Y = Y, plane = plane, rocket = rocket, fire = fire, smoke = smoke }
	end

	-- VŨ TRỤ: Trái Đất, vệ tinh, trạm vũ trụ, Mặt Trăng, quỹ đạo
	SETS.space = function()
		local X = Kit.origin(Vector3.new(4000, 900, -4000))
		local Rr = 700
		for _, f in ipairs({ { Vector3.new(Rr * 2, 2, Rr * 2), Vector3.new(0, Rr, 0) }, { Vector3.new(Rr * 2, 2, Rr * 2), Vector3.new(0, -Rr, 0) }, { Vector3.new(2, Rr * 2, Rr * 2), Vector3.new(Rr, 0, 0) }, { Vector3.new(2, Rr * 2, Rr * 2), Vector3.new(-Rr, 0, 0) }, { Vector3.new(Rr * 2, Rr * 2, 2), Vector3.new(0, 0, Rr) }, { Vector3.new(Rr * 2, Rr * 2, 2), Vector3.new(0, 0, -Rr) } }) do
			box("Void", f[1], X(f[2].X, f[2].Y, f[2].Z), "#020208", nil, { CanCollide = false, CastShadow = false })
		end
		local rng = Random.new(77)
		for k = 1, 500 do
			local d = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit * (Rr - 5)
			ball("Star", rng:NextNumber(0.8, 2.2), X(d.X, d.Y, d.Z), "#ffffff", Enum.Material.Neon, { CanCollide = false, CastShadow = false })
		end
		local earth = ball("Earth", 120, X(0, 0, 0), "#2a6ac8", Enum.Material.SmoothPlastic)
		for k = 1, 18 do
			local d = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.7, 0.7), rng:NextNumber(-1, 1)).Unit * 52
			local land = ball("Land", rng:NextNumber(20, 38), X(d.X, d.Y, d.Z), k % 3 == 0 and "#c8b070" or "#3f8a3a", Enum.Material.Grass)
			land.Size = Vector3.new(land.Size.X, land.Size.Y * 0.7, land.Size.Z)
		end
		for k = 1, 14 do
			local d = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit * 58
			ball("Cloud", rng:NextNumber(10, 18), X(d.X, d.Y, d.Z), "#ffffff", nil, { Transparency = 0.25 })
		end
		local sun = box("SunLight", Vector3.new(4, 4, 4), CFrame.lookAt(X(-600, 200, -300), X(0, 0, 0)), "#fff6d8", Enum.Material.Neon)
		light("SpotLight", sun, { Face = Enum.NormalId.Front, Angle = 40, Range = 900, Brightness = 6, Color = Color3.fromRGB(255, 248, 230) })
		-- vệ tinh trên quỹ đạo
		local sats = {}
		for k = 1, 10 do
			local s = makeSatellite(CFrame.new(X(0, 0, 0)), 1.5)
			table.insert(sats, { m = s, a = k * 0.63, r = 82 + (k % 3) * 6, tilt = (k % 4 - 1.5) * 0.25, speed = 0.35 + (k % 3) * 0.05 })
		end
		local iss = makeSatellite(CFrame.new(X(0, 0, 0)), 4)
		local moon = ball("Moon", 30, X(0, 0, 269), "#c8c8c8", Enum.Material.Slate)
		local escape = 0
		local conn = RunService.Heartbeat:Connect(function(dt)
			for _, s in ipairs(sats) do
				s.a += dt * s.speed
				local r = s.r + escape * (1 + s.a % 1) * 40
				s.m:PivotTo(CFrame.new(X(math.cos(s.a) * r, math.sin(s.a) * r * s.tilt, math.sin(s.a) * r)))
			end
			iss:PivotTo(CFrame.new(X(math.cos(-escape * 2 + 1) * (78 + escape * 60), 10, math.sin(-escape * 2 + 1) * (78 + escape * 60))))
		end)
		local orbitDots = {}
		local function drawOrbit(peri, apo, color)
			for _, d in ipairs(orbitDots) do
				d:Destroy()
			end
			table.clear(orbitDots)
			local a = (peri + apo) / 2
			local e = (apo - peri) / (apo + peri)
			for k = 0, 89 do
				local th = k / 90 * math.pi * 2
				local r = a * (1 - e * e) / (1 + e * math.cos(th)) * 0.7
				table.insert(orbitDots, ball("Orbit", 2.4, X(r * math.cos(th), 0, r * math.sin(th)), color or "#ffd21f", Enum.Material.Neon, { CanCollide = false }))
			end
		end
		return {
			X = X, earth = earth, moon = moon, drawOrbit = drawOrbit,
			setEscape = function(v)
				escape = v
			end,
			stop = function()
				conn:Disconnect()
			end,
		}
	end

	-- BIỂN ĐÊM: tàu câu mực đèn sáng
	SETS.sea = function()
		local B = Kit.origin(Vector3.new(400, 0, -2400))
		box("Sea", Vector3.new(1200, 1, 1200), B(0, -0.5, 0), "#0e2a3a", Enum.Material.Glass, { Reflectance = 0.35 })
		local function boat(x, z, yaw)
			local cf = CFrame.new(B(x, 0, z)) * CFrame.Angles(0, rad(yaw), 0)
			local hull = Kit.box("Hull", Vector3.new(16, 2.4, 5), cf * CFrame.new(0, 0.6, 0), "#2f6ab0", Enum.Material.Wood)
			local parts = {
				hull,
				Kit.box("HullStripe", Vector3.new(16.1, 0.5, 5.1), cf * CFrame.new(0, 1.6, 0), "#c8322f", Enum.Material.Wood),
				Kit.box("Deck", Vector3.new(15, 0.3, 4.6), cf * CFrame.new(0, 1.95, 0), "#8b6a4a", Enum.Material.WoodPlanks),
				Kit.box("Cabin", Vector3.new(4, 3, 3.6), cf * CFrame.new(-3, 3.6, 0), "#f2f2f2", Enum.Material.Wood),
				Kit.box("Mast", Vector3.new(0.3, 8, 0.3), cf * CFrame.new(2, 6, 0), "#5a4430", Enum.Material.Wood),
			}
			for k = 0, 5 do
				local bulb = ball("SquidLamp", 0.6, cf * CFrame.new(-6 + k * 2.4, 5, 0), "#fff8e0", Enum.Material.Neon)
				table.insert(parts, bulb)
				if k % 2 == 0 then
					light("PointLight", bulb, { Range = 16, Brightness = 1.5, Color = Color3.fromRGB(255, 245, 220) })
				end
			end
			return modelOf("Boat", parts, hull)
		end
		local mainBoat = boat(0, 0, 0)
		for k = 1, 9 do
			boat(-160 + k * 34, 60 + (k % 3) * 40, k * 25)
		end
		return { B = B, boat = mainBoat }
	end

	-- BỆNH VIỆN
	SETS.hospital = function()
		local Hh = Kit.origin(Vector3.new(800, 0, -2400))
		box("Floor", Vector3.new(16, 1, 50), Hh(0, -0.5, 0), "#e8ecef", Enum.Material.Marble)
		box("Ceil", Vector3.new(16, 1, 50), Hh(0, 10.5, 0), "#f4f6f8")
		box("WallL", Vector3.new(1, 11, 50), Hh(-8, 5, 0), "#d8e8e4", Enum.Material.Plaster)
		box("WallR", Vector3.new(1, 11, 50), Hh(8, 5, 0), "#d8e8e4", Enum.Material.Plaster)
		box("WallEnd", Vector3.new(16, 11, 1), Hh(0, 5, 25), "#d8e8e4", Enum.Material.Plaster)
		for z = -20, 20, 8 do
			local lamp = box("Lamp", Vector3.new(3, 0.2, 1), Hh(0, 9.9, z), "#ffffff", Enum.Material.Neon)
			light("SurfaceLight", lamp, { Face = Enum.NormalId.Bottom, Range = 14, Brightness = 1.2, Color = Color3.fromRGB(230, 245, 255) })
			box("Bed", Vector3.new(3.6, 1.6, 7), Hh(-5.5, 0.8, z), "#f2f2f2")
			box("Pillow", Vector3.new(3, 0.5, 1.4), Hh(-5.5, 1.85, z + 2.6), "#ffffff", Enum.Material.Fabric)
			cyl("Oxygen", 4, 0.9, Hh(-2.8, 2, z + 2.8), "#2f7a4a", Enum.Material.Metal)
		end
		return { Hh = Hh }
	end

	-- đèn ông sao cho đêm trăng
	local function star(cf, col)
		local center = ball("StarCore", 0.6, cf, col or "#ff3b30", Enum.Material.Neon)
		local parts = { center }
		for k = 0, 4 do
			table.insert(parts, Kit.box("Ray", Vector3.new(0.4, 1.4, 0.15), cf * CFrame.Angles(0, 0, rad(k * 72)) * CFrame.new(0, 0.7, 0), col or "#ff3b30", Enum.Material.Neon))
		end
		light("PointLight", center, { Range = 8, Brightness = 1.2, Color = Color3.fromRGB(255, 90, 70) })
		return modelOf("Lantern", parts, center)
	end

	------------------------------------------------------------------ CÁC CHƯƠNG
	local CH = {}

	local function fallScene(ch, i1, i2)
		Kit.look("morning")
		ctx.setGravity(0.5)
		ctx.placeCrowd()
		Kit.stand(Ban, P(0, 0, -8), P(0, 0, -20))
		showOnly({ Ban, A.KhachA, A.KhachB, A.KhachC, A.KhachD, Linh, Tuan, A.CoBanMi })
		for i, a in ipairs(everyone) do
			Kit.glide(a, a.model:GetPivot() + Vector3.new(0, 5 + (i % 3) * 1.5, 0), 0)
			Kit.pose(a, "cheer", 0.01, false)
			Kit.expr(a, "happy")
		end
		Kit.cam({ pos = P(0, 6, -26), look = P(0, 8, 4), mm = 22, time = 0 })
		L(ch, i1, function()
			for i, a in ipairs(everyone) do
				task.spawn(function()
					local base = a.model:GetPivot()
					local t0 = os.clock()
					while os.clock() - t0 < 3 do
						a.model:PivotTo(base + Vector3.new(0, math.sin((os.clock() - t0) * 2 + i) * 0.4, 0))
						RunService.Heartbeat:Wait()
					end
				end)
			end
		end)
		L(ch, i2, function()
			ctx.setGravity(1)
			for _, a in ipairs(everyone) do
				Kit.pose(a, "flail", 0.1, false)
				Kit.expr(a, "shocked")
				task.spawn(function()
					local cf = a.model:GetPivot()
					Kit.glide(a, CFrame.new(Vector3.new(cf.Position.X, P(0, 0, 0).Y + a.standY, cf.Position.Z)) * cf.Rotation, 0.35, Enum.EasingStyle.Quad)
					Kit.pose(a, "rest", 0.2, false)
					Kit.expr(a, "pain")
				end)
			end
			task.wait(0.35)
			fx("shake", 0.5, 2)
		end)
	end

	-- 1 · MỞ ĐẦU LẠNH
	CH[1] = function()
		fallScene(1, 1, 2)
		Kit.look("night")
		Lighting.ClockTime = 0
		showOnly({})
		sky().MoonAngularSize = 11
		lookAtMoon(P(0, 3, -20), 35)
		L(1, 3, function()
			Kit.tw(sky(), 5, { MoonAngularSize = 5 })
		end)
		fx("title", "NẾU TRỌNG LỰC GIẢM MỘT NỬA", "7 ngày · What if?")
		L(1, 4)
		sky().MoonAngularSize = 11
	end

	-- 2 · LUẬT CHƠI
	CH[2] = function()
		Kit.look("morning")
		ctx.setGravity(1)
		showOnly({ Ban })
		Kit.stand(Ban, P(0, 0, -10), P(0, 0, -20))
		Kit.expr(Ban, "happy")
		chapterCard("LUẬT CHƠI")
		Kit.cam({ pos = P(0, 14, -40), look = P(0, 2, 0), mm = 24, time = 0 })
		L(2, 1)
		Kit.frame(Ban, "FS", { angle = 0, mm = 35 })
		L(2, 2, function()
			Kit.turn(Ban, P(10, 0, -10), 0.8)
			Kit.turn(Ban, P(0, 0, -20), 0.8)
		end)
		Kit.cam({ pos = P(0, 30, -60), look = P(0, 0, 0), mm = 24, time = 0 })
		L(2, 3)
		Kit.frame(Ban, "MCU", { angle = 15, mm = 40 })
		L(2, 4, function()
			task.wait(1.5)
			fx("big", "A. Giao thông\nB. Thời tiết\nC. Một thứ khác?", 4)
		end)
	end

	-- 3 · GIÂY ĐẦU TIÊN (phòng Minh)
	CH[3] = function()
		local r = need("room")
		Kit.look("morning")
		ctx.setGravity(0.5)
		showOnly({ Minh })
		chapterCard("6:00 · NGÀY 1")
		Kit.dress(Minh, { top = "tee", sleeves = "short", topColor = "#8b8e92", bottom = "shorts", bottomColor = "#5a5d62", shoes = "#425850", acc = {} })
		Kit.stand(Minh, r.R(-3, 0, 0), r.R(0, 0, -2))
		Kit.expr(Minh, "groggy")
		Kit.cam({ pos = r.R(6, 6, -7), look = r.R(-4, 3, 2), mm = 24, time = 0 })
		L(3, 1, function()
			Kit.expr(Minh, "smile")
		end)
		Kit.walk(Minh, r.R(0, 0.25, -2), 5)
		Kit.cam({ pos = r.R(0.5, 4, -6), look = r.R(0, 0.3, -2), mm = 35, time = 0 })
		L(3, 2, function()
			for k = 0, 20 do
				r.scaleText.Text = string.format("%.1f", 55 * k / 20)
				task.wait(0.05)
			end
			task.wait(0.4)
			for k = 0, 20 do
				r.scaleText.Text = string.format("%.1f", 55 - 27.5 * k / 20)
				task.wait(0.06)
			end
			Kit.expr(Minh, "shocked")
		end)
		Kit.frame(Minh, "MCU", { angle = 20, mm = 40 })
		L(3, 3, function()
			Kit.pose(Minh, "touchEar", 0.3)
			Kit.expr(Minh, "pain")
		end)
		Kit.pose(Minh, "rest", 0.2, false)
		Kit.cam({ pos = r.R(0, 30, -20), look = r.R(0, 0, 0), mm = 30, time = 0 })
		L(3, 4)
		Kit.walk(Minh, r.R(-8, 0, -4.4), 6)
		Kit.turn(Minh, r.R(-9, 0, -6), 0.3)
		Kit.cam({ pos = r.R(-6.5, 5, -4), look = r.R(-9, 3.5, -6.5), mm = 40, time = 0, dof = 0.4 })
		r.water.Rate = 120
		r.water.Speed = NumberRange.new(10)
		L(3, 5, function()
			task.wait(1.5)
			Kit.tw(r.water, 1, { Rate = 50 })
			r.water.Speed = NumberRange.new(5)
			r.water.Acceleration = Vector3.new(0, -30, 0)
		end)
		r.water.Rate = 0
		r.potLabel.Enabled = true
		Kit.cam({ pos = r.R(5.5, 6, -6.5), look = r.R(8.8, 4, -4), mm = 40, time = 0, dof = 0.4 })
		L(3, 6)
		r.potLabel.Enabled = false
	end

	-- 4 · BUỔI SÁNG CỦA MỘT NGƯỜI HÀ NỘI
	CH[4] = function()
		local st = need("stairs")
		Kit.look("morning")
		ctx.setGravity(0.5)
		showOnly({ Minh })
		chapterCard("MINH · 25 tuổi · nhân viên văn phòng")
		Kit.dress(Minh, CAST.Minh.outfit)
		Kit.stand(Minh, st.S(-22, 25, 5.5), st.S(-10, 25, 5.5))
		Kit.expr(Minh, "happy")
		Kit.cam({ pos = st.S(-12, 27, -6), look = Kit.on(Minh, "Head"), mm = 35, time = 0, smooth = 4 })
		L(4, 1)
		Kit.cam({ pos = st.S(0, 14, -22), look = Kit.on(Minh, "UpperTorso"), mm = 30, time = 0, smooth = 5 })
		L(4, 2, function()
			Kit.turn(Minh, st.S(20, 0, 1.5), 0.2)
			for i = 0, 38, 3 do
				hop(Minh, st.S(-20 + i + 3, 25 - (i + 3) * 0.625 - 0.05, 1.5), 1.6, 0.45)
			end
			Kit.expr(Minh, "laugh")
		end)
		-- gánh xôi
		local ph = need("pho")
		showOnly({ A.CoXoi, Minh })
		Kit.hide(Minh)
		Kit.stand(A.CoXoi, P(-60, 0.3, -56), P(0, 0.3, -56))
		Kit.expr(A.CoXoi, "happy")
		Kit.pose(A.CoXoi, "phoneEar", 0.01, false)
		Kit.grab(A.CoXoi, ph.ganh, "RightHand", CFrame.new(0, 0.6, 0) * CFrame.Angles(0, rad(90), 0))
		Kit.frame(A.CoXoi, "FS", { angle = 70, mm = 30, smooth = 4 })
		L(4, 3, function()
			task.spawn(function()
				for k = 1, 8 do
					hop(A.CoXoi, P(-60 + k * 2.5, 0.3, -56), 0.8, 0.45)
				end
			end)
		end)
		-- bát phở
		Kit.hide(A.CoXoi)
		showOnly({ Minh, A.ChuPho })
		Kit.sit(Minh, ph.T + Vector3.new(-1.6, 0, 1.9), 1.4, ph.T + Vector3.new(-1.6, 0, 0))
		Kit.stand(A.ChuPho, ph.T + Vector3.new(3, 0, -1.5), ph.T)
		Kit.expr(Minh, "happy")
		Kit.cam({ pos = ph.T + Vector3.new(1.2, 4.2, -2.4), look = ph.T + Vector3.new(0, 3.2, 0), mm = 50, time = 0, dof = 0.5, focusRadius = 1 })
		L(4, 4, function()
			for k = 1, 10 do
				local tilt = math.sin(k * 0.9) * (12 / k) + 2
				for _, p in ipairs(ph.bowl) do
					Kit.tw(p, 0.25, { CFrame = CFrame.new(p.Position) * CFrame.Angles(rad(tilt), 0, rad(90 + tilt * 0.6)) })
				end
				task.wait(0.27)
			end
		end)
		-- nhấc xe máy
		Kit.stand(Minh, P(-24, 0.3, -55.2), P(-24, 0.3, -53))
		Kit.frame(Minh, "MLS", { angle = 50, mm = 30 })
		L(4, 5, function()
			Kit.pose(Minh, "reach", 0.3)
			local cf = ph.moto:GetPivot()
			ctx.moveModel(ph.moto, cf * CFrame.new(0, 0, 0) * CFrame.Angles(rad(20), 0, 0), 0.6, Enum.EasingStyle.Quad)
			task.wait(1.6)
			ctx.moveModel(ph.moto, cf, 0.5, Enum.EasingStyle.Quad)
		end)
		Kit.frame(Minh, "MCU", { angle = 10, mm = 40 })
		task.wait(0.05)
		Kit.frame(Minh, "WS", { angle = 10, mm = 28, time = 4 })
		L(4, 6, function()
			task.wait(2)
			Kit.expr(Minh, "neutral")
		end)
		Kit.pose(Minh, "rest", 0.2, false)
	end

	-- 5 · NGÀY 1: THIÊN ĐƯỜNG THỂ THAO
	CH[5] = function()
		Kit.look("afternoon")
		ctx.setGravity(0.5)
		ctx.placeCrowd()
		showOnly({ Ban, A.KhachA, A.KhachB, A.KhachC, A.KhachD, Linh, Tuan, A.CoBanMi })
		chapterCard("NGÀY 1")
		Kit.cam({ pos = P(-28, 18, -40), look = P(0, 2, 10), mm = 24, time = 0 })
		L(5, 1, function()
			for i, a in ipairs(ctx.crowd) do
				task.delay(i * 0.3, ctx.jump, a, 6, 1.4, 0)
			end
		end)
		Kit.stand(Ban, P(-6, 0, 4), P(-6, 0, -10))
		Kit.stand(Linh, P(-2, 0, 4), P(-2, 0, -10))
		Kit.cam({ pos = P(-4, 4, -10), look = P(-4, 4.5, 4), mm = 28, time = 0 })
		L(5, 2, function()
			task.spawn(ctx.jump, Linh, 4, 1.3, 0)
			ctx.jump(Ban, 4, 1.3, 0)
		end)
		-- xà nhảy cao
		local barY = 3.7 / 0.28
		box("HJPostL", Vector3.new(0.4, barY + 1, 0.4), P(22, (barY + 1) / 2, 0), "#e8e8e8", Enum.Material.Metal)
		box("HJPostR", Vector3.new(0.4, barY + 1, 0.4), P(22, (barY + 1) / 2, 12), "#e8e8e8", Enum.Material.Metal)
		box("HJBar", Vector3.new(0.3, 0.3, 12), P(22, barY, 6), "#e2652b")
		box("HJMat", Vector3.new(8, 2, 14), P(27, 1, 6), "#2f6ab0", Enum.Material.Fabric)
		Kit.stand(Tuan, P(12, 0, 6), P(30, 0, 6))
		Kit.cam({ pos = P(22, 7, -16), look = P(22, 9, 6), mm = 24, time = 0 })
		L(5, 3, function()
			task.wait(0.8)
			hop(Tuan, P(27, 2, 6), barY - 1, 1.8)
		end)
		Kit.stand(Tuan, P(-32, 0, 14), P(-32, 0, 30))
		Kit.frame(Tuan, "FS", { angle = -30, mm = 28, height = 2 })
		L(5, 4, function()
			Kit.walk(Tuan, P(-32, 0, 21), 10)
			ctx.jump(Tuan, 3.6, 1.5, 0, "reachUp")
			Kit.expr(Tuan, "laugh")
		end)
		local soccer = ball("Football", 1.1, P(-14, 0.6, -6), "#f2f2f2")
		soccer.Anchored = false
		Kit.stand(Ban, P(-16, 0, -6), P(10, 0, -6))
		Kit.cam({ pos = P(-6, 6, -24), look = P(4, 4, -4), mm = 24, time = 0 })
		L(5, 5, function()
			task.wait(0.3)
			Kit.pose(Ban, "reach", 0.15)
			soccer.AssemblyLinearVelocity = Vector3.new(34, 30, 0)
			local t0 = os.clock()
			while os.clock() - t0 < 2.6 do
				fx("cam", { pos = P(-6, 6, -24), look = soccer.Position, fov = 40, time = 0, smooth = 6, drift = 0 })
				task.wait(0.1)
			end
		end)
		soccer:Destroy()
		Kit.stand(Ban, P(-20, 0, 0), P(20, 0, 0))
		Kit.frame(Ban, "FS", { angle = 80, mm = 30, smooth = 4 })
		L(5, 6, function()
			for k = 1, 8 do
				hop(Ban, P(-20 + k * 3.5, 0, 0), 1.2, 0.5)
			end
			Kit.expr(Ban, "laugh")
		end)
		Kit.cam({ pos = P(10, 3, -10), look = P(0, 4, 10), mm = 30, time = 0 })
		L(5, 7)
	end

	-- 6 · TỐI NGÀY 1: CƠN SỐT TRÊN MẠNG
	CH[6] = function()
		Kit.look("night")
		ctx.setGravity(0.5)
		showOnly({ Ban })
		chapterCard("TỐI NGÀY 1")
		Kit.stand(Ban, P(-6, 0, -25.5), P(-6, 0, -40))
		Kit.cam({ pos = P(9, 2, -31), look = P(-6, 6, -30), mm = 22, time = 0, occlude = false })
		fx("phone", { title = "TikTok · Xu hướng", msgs = { { me = false, text = "#nhayquaxe 12,4 triệu lượt xem 🔥" }, { me = false, text = "#lon3vong 8,1 triệu" }, { me = false, text = "#nhaytutang2 ⚠️ 5,6 triệu" } }, status = "" })
		L(6, 1, function()
			task.wait(0.5)
			ctx.jump(Ban, 9, 1.6, 10, "cheer")
		end)
		fx("phoneHide")
		local amb = ctx.car("Ambulance", CFrame.new(P(-80, 0, -42)), "#f2f2f2")
		local siren = ball("Siren", 0.8, amb:GetPivot() * CFrame.new(0, 4.4, 0).Position, "#ff3b30", Enum.Material.Neon)
		siren.Anchored = false
		weld(amb.PrimaryPart, siren)
		light("PointLight", siren, { Range = 20, Brightness = 3, Color = Color3.fromRGB(255, 60, 60) })
		ctx.label(amb, "CẤP CỨU 115", Color3.fromRGB(200, 40, 40))
		Kit.cam({ pos = P(-20, 4, -30), look = P(-40, 2, -42), mm = 28, time = 0, smooth = 3 })
		L(6, 2, function()
			ctx.moveModel(amb, CFrame.new(P(60, 0, -42)), 5)
		end)
		Kit.cam({ pos = P(36, 10, -10), look = P(36, 5, -24), mm = 30, time = 0 })
		L(6, 3)
		fx("phone", { title = "THỜI SỰ · Bộ Y tế", msgs = { { me = false, text = "⚠️ KHÔNG nhảy từ trên cao xuống dù trọng lực đang yếu!" } }, status = "Tin khẩn" })
		Kit.cam({ pos = P(0, 20, -50), look = P(0, 0, 0), mm = 24, time = 0 })
		L(6, 4)
		fx("phoneHide")
		amb:Destroy()
		L(6, 5)
	end

	-- 7 · CHÓ MÈO VÀ CHIM CHÓC
	CH[7] = function()
		local r = need("room")
		Kit.look("morning")
		showOnly({})
		chapterCard("CHÓ MÈO VÀ CHIM CHÓC")
		r.cat:PivotTo(CFrame.new(r.R(5, 0, 2)) * CFrame.Angles(0, rad(-90), 0))
		Kit.cam({ pos = r.R(0, 4, -6), look = r.R(7, 5, 5), mm = 24, time = 0 })
		L(7, 1, function()
			task.wait(0.5)
			hopModel(r.cat, r.R(8.8, 6.5, 6.5), 4, 1.1)
			task.wait(0.6)
			hopModel(r.cat, r.R(4, 8.5, 7.8), 3, 1)
		end)
		local dog = makeDog(CFrame.new(P(-10, 0, 0)))
		Kit.cam({ pos = P(0, 4, -14), look = P(0, 2, 0), mm = 28, time = 0, smooth = 4 })
		L(7, 2, function()
			for k = 1, 6 do
				hopModel(dog, P(-10 + k * 3.5, 0, (k % 2) * 1.5), 1.4, 0.45)
			end
		end)
		dog:Destroy()
		local birds = {}
		for k = 1, 9 do
			table.insert(birds, makeBird(CFrame.new(P(-30 + (k % 3) * 2, 18 + math.floor(k / 3) * 1.5, 40 - k * 1.5)) * CFrame.Angles(0, rad(-90), 0)))
		end
		Kit.cam({ pos = P(-10, 10, 10), look = P(-28, 18, 34), mm = 30, time = 0 })
		L(7, 3)
		Kit.cam({ pos = P(0, 12, 0), look = P(10, 20, 30), mm = 24, time = 0, smooth = 3 })
		L(7, 4, function()
			for i, b in ipairs(birds) do
				task.spawn(ctx.moveModel, b, b:GetPivot() + Vector3.new(60, 6, -40 + i), 6)
			end
		end)
		L(7, 5)
		for _, b in ipairs(birds) do
			b:Destroy()
		end
	end

	-- 8 · NGÀY 2: GIAO THÔNG HỖN LOẠN
	CH[8] = function()
		Kit.look("morning")
		ctx.setGravity(0.5)
		showOnly({ Minh })
		chapterCard("NGÀY 2 · 7:00")
		local traffic = {}
		for k = 0, 7 do
			table.insert(traffic, makeMoto(CFrame.new(P(-90 + k * 7, 0, -38 - (k % 2) * 4)), ({ "#c8322f", "#2a4d8f", "#e6e6e6", "#e2a32b" })[k % 4 + 1]))
		end
		Kit.cam({ pos = P(-20, 12, -20), look = P(-40, 2, -40), mm = 26, time = 0 })
		L(8, 1, function()
			for i, m in ipairs(traffic) do
				ctx.moveModel(m, m:GetPivot() + Vector3.new(60, 0, 0), 5 + i * 0.2)
			end
		end)
		Kit.cam({ pos = P(-6, 1.2, -36), look = P(-6, 1, -30.5), mm = 50, time = 0, dof = 0.5, focusRadius = 1.5, occlude = false })
		L(8, 2)
		ctx.carA:PivotTo(CFrame.new(P(-70, 0, -38)))
		ctx.carB:PivotTo(CFrame.new(P(-70, 0, -46)))
		local la = ctx.label(ctx.carA, "Trọng lực bình thường", Color3.fromRGB(40, 120, 200))
		local lb = ctx.label(ctx.carB, "Trọng lực 50%", Color3.fromRGB(200, 50, 50))
		Kit.cam({ pos = P(-10, 14, -20), look = P(-20, 1, -42), mm = 26, time = 0 })
		L(8, 3, function()
			ctx.moveModel(ctx.carA, CFrame.new(P(-30, 0, -38)), 1.6)
			ctx.moveModel(ctx.carB, CFrame.new(P(-30, 0, -46)), 1.6)
			task.wait(1.7)
			ctx.moveModel(ctx.carA, CFrame.new(P(-14, 0, -38)), 1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			ctx.moveModel(ctx.carB, CFrame.new(P(2, 0, -46)), 2.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end)
		la:Destroy()
		lb:Destroy()
		local bike = makeMoto(CFrame.new(P(-40, 0, -46)), "#e2a32b")
		Kit.cam({ pos = P(-26, 10, -60), look = P(-20, 1, -44), mm = 28, time = 0 })
		L(8, 4, function()
			ctx.moveModel(bike, CFrame.new(P(-20, 0, -44)) * CFrame.Angles(rad(-25), rad(-30), 0), 1.5, Enum.EasingStyle.Sine)
			task.wait(1.5)
			ctx.moveModel(bike, CFrame.new(P(-10, 0, -50)) * CFrame.Angles(rad(-60), rad(-50), 0), 1, Enum.EasingStyle.Quad)
		end)
		bike:Destroy()
		-- Minh suýt đâm xe buýt
		local bus = ctx.car("Bus", CFrame.new(P(10, 0, -42)), "#2f7a4a")
		bus:ScaleTo(1.6)
		local mm = makeMoto(CFrame.new(P(-30, 0, -42)), "#2a4d8f")
		Kit.stand(Minh, P(-30, 0, -42), P(0, 0, -42))
		Kit.sit(Minh, P(-30.4, 0, -42), 2.3, P(0, 0, -42))
		Kit.expr(Minh, "shocked")
		Kit.cam({ pos = P(-4, 3, -32), look = P(-14, 3, -42), mm = 30, time = 0 })
		L(8, 5, function()
			local t = 3.2
			ctx.moveModel(mm, CFrame.new(P(-1.5, 0, -42)), t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local v = Instance.new("CFrameValue")
			v.Value = Minh.model:GetPivot()
			v.Changed:Connect(function(c)
				Minh.model:PivotTo(c)
			end)
			Kit.tw(v, t, { Value = v.Value + Vector3.new(28.5, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			task.wait(t)
			fx("shake", 0.3, 1)
			Kit.expr(Minh, "scared")
		end)
		mm:Destroy()
		bus:Destroy()
		Kit.hide(Minh)
		local jam = {}
		for k = 0, 30 do
			table.insert(jam, makeMoto(CFrame.new(P(-60 + (k % 10) * 6, 0, -36 - math.floor(k / 10) * 4)) * CFrame.Angles(0, rad(math.random(-15, 15)), 0), ({ "#c8322f", "#2a4d8f", "#e6e6e6", "#e2a32b", "#2f2f2f" })[k % 5 + 1]))
		end
		Kit.cam({ pos = P(-30, 24, -10), look = P(-30, 0, -42), mm = 26, time = 0 })
		L(8, 6)
		for _, m in ipairs(jam) do
			m:Destroy()
		end
		for _, m in ipairs(traffic) do
			m:Destroy()
		end
		local ap = need("airport")
		Kit.fx("cam", { pos = ap.Y(-60, 6, -40), look = ap.Y(-130, 5, 0), fov = 34, time = 0 })
		L(8, 7, function()
			ctx.moveModel(ap.plane, CFrame.new(ap.Y(40, 0.3, 0)), 5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.wait(4)
			ctx.moveModel(ap.plane, CFrame.new(ap.Y(140, 30, 0)) * CFrame.Angles(0, 0, rad(10)), 3)
		end)
		ap.plane:PivotTo(CFrame.new(ap.Y(-130, 0.3, 0)))
		L(8, 8)
	end

	-- 9 · TỐI NGÀY 2: TRẬN BÓNG ĐÁ
	CH[9] = function()
		local sd = need("stadium")
		Kit.look("night")
		ctx.setGravity(0.5)
		showOnly({ A.CauThu1, A.CauThu2, A.ThuMon })
		chapterCard("TỐI NGÀY 2")
		Kit.stand(A.ThuMon, sd.D(-48, 0, 0), sd.D(0, 0, 0))
		Kit.stand(A.CauThu1, sd.D(-10, 0, 6), sd.D(-48, 0, 0))
		Kit.stand(A.CauThu2, sd.D(5, 0, -4), sd.D(-48, 0, 0))
		sd.scoreText.Text = "0 – 0"
		Kit.cam({ pos = sd.D(-70, 40, -80), look = sd.D(0, 0, 0), mm = 22, time = 0 })
		task.wait(0.05)
		Kit.cam({ pos = sd.D(-40, 22, -60), look = sd.D(0, 0, 0), mm = 22, time = 6 })
		L(9, 1)
		local b = ball("Ball", 1.1, sd.D(-46, 0.6, 0), "#f2f2f2")
		b.Anchored = false
		Kit.cam({ pos = sd.D(-60, 10, -40), look = sd.D(-46, 1, 0), mm = 24, time = 0 })
		L(9, 2, function()
			task.wait(0.6)
			Kit.pose(A.ThuMon, "reach", 0.15)
			b.AssemblyLinearVelocity = Vector3.new(80, 64, 0)
			local t0 = os.clock()
			while os.clock() - t0 < 3.4 do
				fx("cam", { pos = sd.D(-20, 30, -70), look = b.Position, fov = 45, time = 0, smooth = 5, drift = 0 })
				task.wait(0.1)
			end
		end)
		L(9, 3)
		b:Destroy()
		Kit.frame(A.CauThu1, "FS", { angle = 60, mm = 28 })
		L(9, 4, function()
			ctx.jump(A.CauThu1, 8, 1.8, 0, "cheer")
			Kit.expr(A.CauThu2, "shocked")
			hop(A.CauThu2, sd.D(9, 0, -2), 2, 0.6)
			Kit.glide(A.CauThu2, A.CauThu2.model:GetPivot() * CFrame.Angles(rad(70), 0, 0) - Vector3.new(0, 1.8, 0), 0.4)
		end)
		Kit.stand(A.CauThu2, sd.D(5, 0, -4), sd.D(-48, 0, 0))
		Kit.expr(A.CauThu1, "tired")
		Kit.expr(A.CauThu2, "tired")
		Kit.pose(A.CauThu1, "kneesTired", 0.3, false)
		Kit.frame(A.CauThu1, "MS", { angle = 20, mm = 35 })
		L(9, 5)
		sd.scoreText.Text = "9 – 7"
		Kit.cam({ pos = sd.D(0, 20, 30), look = sd.D(0, 26, 66), mm = 35, time = 0 })
		L(9, 6)
		ctx.setGravity(0.5)
	end

	-- 10 · AI ĐƯỢC LỢI?
	CH[10] = function()
		local mk = need("market")
		Kit.look("morning")
		ctx.setGravity(0.5)
		showOnly({ A.KhachB, A.KhachD, A.Shipper, Tuan })
		chapterCard("AI ĐƯỢC LỢI?")
		Kit.stand(A.KhachB, mk.K(-46, 0, -2), mk.K(0, 0, -2))
		local s1, s2 = mk.sacks[1], mk.sacks[2]
		Kit.pose(A.KhachB, "cheer", 0.01, false)
		Kit.grab(A.KhachB, s1, "RightHand", CFrame.new(0, 0.8, 0))
		Kit.grab(A.KhachB, s2, "LeftHand", CFrame.new(0, 0.8, 0))
		Kit.frame(A.KhachB, "FS", { angle = 60, mm = 28, smooth = 4 })
		L(10, 1, function()
			Kit.walk(A.KhachB, mk.K(-30, 0, -2), 5)
		end)
		Kit.cam({ pos = mk.K(0, 10, -10), look = mk.K(20, 30, 30), mm = 24, time = 0 })
		L(10, 2, function()
			ctx.moveModel(mk.crane, CFrame.new(mk.K(20, 30, 30)), 5, Enum.EasingStyle.Sine)
		end)
		Kit.stand(Tuan, mk.K(-11.8, 0, 14), mk.K(-10, 0, 14))
		Kit.stand(A.KhachD, mk.K(-8.2, 0, 14), mk.K(-10, 0, 14))
		Kit.pose(Tuan, "offer", 0.01, false)
		Kit.pose(A.KhachD, "offer", 0.01, false)
		Kit.expr(Tuan, "happy")
		Kit.expr(A.KhachD, "happy")
		Kit.cam({ pos = mk.K(-10, 6, 2), look = mk.K(-10, 4, 14), mm = 28, time = 0 })
		L(10, 3, function()
			local up = Vector3.new(0, 2, 0)
			ctx.moveModel(Tuan.model, Tuan.model:GetPivot() + up, 1)
			ctx.moveModel(A.KhachD.model, A.KhachD.model:GetPivot() + up, 1)
			Kit.tw(mk.fridge, 1, { CFrame = mk.fridge.CFrame + up })
		end)
		Kit.resetPose(Tuan)
		Kit.resetPose(A.KhachD)
		Kit.hide(Tuan)
		Kit.sit(A.Shipper, mk.K(-60.3, 0, 26), 2.3, mk.K(0, 0, 26))
		Kit.cam({ pos = mk.K(-40, 4, 16), look = mk.K(-60, 4, 26), mm = 30, time = 0 })
		L(10, 4, function()
			local d = Vector3.new(30, 0, 0)
			ctx.moveModel(mk.moto, mk.moto:GetPivot() + d, 4)
			ctx.moveModel(A.Shipper.model, A.Shipper.model:GetPivot() + d, 4)
		end)
		Kit.hide(A.Shipper)
		Kit.stand(A.KhachD, mk.K(-20, 0, 0), mk.K(20, 0, 0))
		Kit.expr(A.KhachD, "smile")
		Kit.frame(A.KhachD, "FS", { angle = 70, mm = 30, smooth = 4 })
		L(10, 5, function()
			Kit.walk(A.KhachD, mk.K(-8, 0, 0), 2.5)
		end)
		Kit.look("rain")
		Kit.cam({ pos = mk.K(0, 4, -20), look = mk.K(0, 40, 40), mm = 22, time = 0 })
		L(10, 6)
	end

	-- 11 · NGÀY 3: MƯA, SÔNG VÀ TRIỀU CƯỜNG
	CH[11] = function()
		Kit.look("rain")
		ctx.setGravity(0.5)
		showOnly({ Linh })
		chapterCard("NGÀY 3")
		fx("rain", true)
		Kit.cam({ pos = P(-20, 8, -20), look = P(0, 2, 10), mm = 26, time = 0 })
		L(11, 1)
		Kit.cam({ pos = P(-4, 3, -6), look = P(0, 8, 10), mm = 40, time = 0, dof = 0.3 })
		L(11, 2)
		Kit.cam({ pos = P(0, 3, -4), look = P(0, 14, 14), mm = 24, time = 0 })
		L(11, 3)
		local fl = need("flood")
		Kit.stand(Linh, fl.W(0, 0.3, 2), fl.W(10, 0, 2))
		Kit.pose(Linh, "reachUp", 0.01, false)
		Kit.frame(Linh, "FS", { angle = 60, mm = 28, smooth = 3 })
		fl.umbrella.CFrame = CFrame.new(fl.W(0, 8.5, 2))
		L(11, 4, function()
			task.wait(1)
			Kit.tw(fl.umbrella, 1.6, { CFrame = CFrame.new(fl.W(18, 14, 6)) * CFrame.Angles(rad(60), 0, rad(40)) })
			Kit.pose(Linh, "flail", 0.2, false)
			Kit.expr(Linh, "shocked")
			local v = Instance.new("CFrameValue")
			v.Value = Linh.model:GetPivot()
			v.Changed:Connect(function(c)
				Linh.model:PivotTo(c)
			end)
			Kit.tw(v, 2.2, { Value = v.Value + Vector3.new(6, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end)
		Kit.hide(Linh)
		Kit.cam({ pos = fl.W(-30, 6, 40), look = fl.W(0, 0, 60), mm = 26, time = 0 })
		L(11, 5, function()
			Kit.tw(fl.flood, 5, { CFrame = CFrame.new(fl.W(0, -0.2, 0)) })
		end)
		Kit.cam({ pos = fl.W(-50, 10, 70), look = fl.W(0, 0, 40), mm = 24, time = 0 })
		L(11, 6, function()
			Kit.tw(fl.flood, 6, { CFrame = CFrame.new(fl.W(0, 0.6, 0)) })
		end)
		Kit.cam({ pos = fl.W(-60, 22, -40), look = fl.W(0, 0, 10), mm = 24, time = 0 })
		L(11, 7, function()
			Kit.tw(fl.flood, 8, { CFrame = CFrame.new(fl.W(0, 1.8, 0)) })
		end)
		Kit.cam({ pos = fl.W(0, 3, 0), look = fl.W(0, 100, 30), mm = 22, time = 0, occlude = false })
		L(11, 8)
		fx("rain", false)
		fl.flood.CFrame = CFrame.new(fl.W(0, -1, 0))
	end

	-- 12 · NGÀY 4: BẦU TRỜI TRỐNG RỖNG
	CH[12] = function()
		local sp = need("space")
		Kit.look("night")
		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then
			atm.Density = 0
		end
		showOnly({})
		chapterCard("NGÀY 4")
		sp.setEscape(0)
		Kit.cam({ pos = sp.X(-60, 60, -230), look = sp.X(0, 0, 0), mm = 30, time = 0, occlude = false })
		L(12, 1)
		Kit.cam({ pos = sp.X(-60, 120, -330), look = sp.X(0, 0, 0), mm = 30, time = 0, occlude = false })
		L(12, 2, function()
			local t0 = os.clock()
			while os.clock() - t0 < 5 do
				sp.setEscape((os.clock() - t0) / 5)
				task.wait()
			end
		end)
		L(12, 3, function()
			local t0 = os.clock()
			while os.clock() - t0 < 5 do
				sp.setEscape(1 + (os.clock() - t0) / 3)
				task.wait()
			end
		end)
		Kit.look("morning")
		showOnly({ Minh })
		Kit.stand(Minh, P(0, 0, -20), P(0, 0, -40))
		Kit.pose(Minh, "phoneLook", 0.01, false)
		Kit.expr(Minh, "worried")
		Kit.frame(Minh, "MCU", { angle = 15, mm = 40 })
		fx("phone", { title = "Google Maps", msgs = { { me = false, text = "⚠️ Mất tín hiệu GPS" }, { me = false, text = "Đang tìm vệ tinh..." } }, status = "" })
		L(12, 4)
		fx("phoneHide")
		Kit.cam({ pos = P(0, 30, -60), look = P(0, 0, 0), mm = 24, time = 0 })
		L(12, 5)
		local ap = need("airport")
		Kit.cam({ pos = ap.Y(20, 8, 20), look = ap.Y(60, 30, 90), mm = 22, time = 0 })
		L(12, 6, function()
			ap.fire.Rate = 300
			ap.smoke.Rate = 80
			fx("shake", 2, 0.8)
			ctx.moveModel(ap.rocket, ap.rocket:GetPivot() + Vector3.new(0, 400, 0), 7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local t0 = os.clock()
			while os.clock() - t0 < 6 do
				fx("cam", { pos = ap.Y(20, 8, 20), look = ap.rocket.PrimaryPart.Position, fov = 40, time = 0, smooth = 4, drift = 0, occlude = false })
				task.wait(0.1)
			end
		end)
		ap.fire.Rate, ap.smoke.Rate = 0, 0
		ap.rocket:PivotTo(CFrame.new(ap.Y(60, 2, 90)))
		Kit.look("night")
		Lighting.ClockTime = 0
		showOnly({})
		lookAtMoon(P(0, 3, -20), 35)
		L(12, 7)
	end

	-- 13 · TỐI NGÀY 4: NHỮNG CON THUYỀN NGOÀI KHƠI
	CH[13] = function()
		local se = need("sea")
		Kit.look("night")
		Lighting.ClockTime = 0
		sky().MoonAngularSize = 9
		showOnly({ A.OngLao })
		chapterCard("TỐI NGÀY 4 · Biển Đông")
		Kit.stand(A.OngLao, se.B(4, 2.1, 0), se.B(20, 2.1, 0))
		Kit.expr(A.OngLao, "serious")
		Kit.cam({ pos = se.B(-30, 12, -40), look = se.B(0, 2, 0), mm = 26, time = 0 })
		L(13, 1)
		fx("phone", { title = "Định vị tàu cá", msgs = { { me = false, text = "KHÔNG CÓ TÍN HIỆU VỆ TINH" } }, status = "" })
		Kit.frame(A.OngLao, "MCU", { angle = 30, mm = 40 })
		L(13, 2)
		fx("phoneHide")
		Kit.gaze(A.OngLao, 0, -1)
		Kit.frame(A.OngLao, "MS", { angle = -40, mm = 35, height = -1 })
		L(13, 3)
		lookAtMoon(se.B(4, 6, 0), 60)
		L(13, 4)
		Kit.frame(A.OngLao, "CU", { angle = 20, mm = 50 })
		Kit.expr(A.OngLao, "worried")
		L(13, 5)
		sky().MoonAngularSize = 11
	end

	-- 14 · NGÀY 5: SỐNG NHƯ Ở TRẠI NỀN EVEREST
	CH[14] = function()
		Kit.look("afternoon")
		ctx.setGravity(0.5)
		showOnly({ Ban })
		chapterCard("NGÀY 5")
		Kit.stand(Ban, P(0, 0, -10), P(0, 0, -20))
		Kit.expr(Ban, "tired")
		Kit.frame(Ban, "MS", { angle = 10, mm = 35 })
		L(14, 1)
		Kit.cam({ pos = P(0, 3, -20), look = P(0, 60, 40), mm = 22, time = 0 })
		L(14, 2)
		Kit.frame(Ban, "MCU", { angle = -15, mm = 40 })
		L(14, 3)
		Kit.frame(Ban, "CU", { angle = 0, mm = 45 })
		Kit.expr(Ban, "sad")
		L(14, 4)
		local r = need("room")
		showOnly({ Minh })
		Kit.look("night")
		Kit.glide(Minh, CFrame.new(r.R(-7, 2.4, 3.5)) * CFrame.Angles(rad(90), 0, 0), 0)
		Minh.model.Parent = Kit.ACTORS
		Kit.expr(Minh, "tired")
		Kit.cam({ pos = r.R(-3, 7, -1), look = r.R(-7, 2, 3.5), mm = 35, time = 0 })
		L(14, 5, function()
			for k = 1, 3 do
				Kit.glide(Minh, Minh.model:GetPivot() * CFrame.Angles(0, rad(20), 0), 0.8)
				Kit.glide(Minh, Minh.model:GetPivot() * CFrame.Angles(0, rad(-20), 0), 0.8)
			end
		end)
		Kit.look("afternoon")
		showOnly({ Ban })
		Kit.stand(Ban, P(36, 0, -22), P(50, 0, -22))
		Kit.frame(Ban, "FS", { angle = -60, mm = 28, smooth = 4 })
		L(14, 6, function()
			local steps = {}
			for i = 0, 8 do
				table.insert(steps, P(36.5 + i, 0.55 * (i + 1), -24))
			end
			Kit.walk(Ban, steps, 3)
			Kit.pose(Ban, "kneesTired", 0.4)
		end)
		local hs = need("hospital")
		showOnly({ A.YTa })
		Kit.stand(A.YTa, hs.Hh(2, 0, -20), hs.Hh(2, 0, 20))
		Kit.expr(A.YTa, "worried")
		Kit.cam({ pos = hs.Hh(4, 6, -24), look = hs.Hh(-2, 3, 10), mm = 28, time = 0, smooth = 4 })
		L(14, 7, function()
			Kit.walk(A.YTa, hs.Hh(2, 0, 10), 6)
		end)
		showOnly({ A.CoBanMi })
		Kit.stand(A.CoBanMi, P(14, 0, -26), P(14, 0, -40))
		ctx.thermo.Enabled = true
		Kit.cam({ pos = P(10, 7.5, -34), look = P(15, 4.4, -28.5), mm = 35, time = 0, dof = 0.4, focusRadius = 2 })
		L(14, 8)
		ctx.thermo.Enabled = false
		L(14, 9)
	end

	-- 15 · NGÀY 6: MẶT TRĂNG BỎ ĐI
	CH[15] = function()
		Kit.look("night")
		Lighting.ClockTime = 0
		ctx.placeCrowd()
		showOnly({ Ban, A.KhachA, A.KhachB, A.KhachC, A.KhachD, Linh })
		chapterCard("NGÀY 6")
		local s = sky()
		s.MoonAngularSize = 11
		lookAtMoon(P(0, 3, -20), 35)
		L(15, 1, function()
			Kit.tw(s, 6, { MoonAngularSize = 8 })
		end)
		L(15, 2)
		local sp = need("space")
		sp.setEscape(3)
		sp.drawOrbit(384, 384, "#7fbfff")
		Kit.cam({ pos = sp.X(0, 600, -1), look = sp.X(0, 0, 0), mm = 18, time = 0, occlude = false })
		L(15, 3, function()
			task.wait(1)
			Kit.tw(sp.moon, 3, { CFrame = CFrame.new(sp.X(0, 0, 398)) })
		end)
		sp.moon.CFrame = CFrame.new(sp.X(0, 0, 269))
		local se = need("sea")
		Kit.cam({ pos = se.B(-80, 6, -80), look = se.B(0, 0, 0), mm = 24, time = 0 })
		L(15, 4)
		local lanterns = {}
		for i, a in ipairs({ A.KhachC, A.KhachA, Linh }) do
			Kit.pose(a, "reachUp", 0.01, false)
			local l = star(CFrame.new(a.head.Position + Vector3.new(0.5, 3, 0)), i % 2 == 0 and "#ffd21f" or "#ff3b30")
			l.PrimaryPart.Anchored = false
			weld(a.model.RightHand, l.PrimaryPart)
			table.insert(lanterns, l)
		end
		Kit.cam({ pos = P(-6, 5, -16), look = P(0, 3, 0), mm = 30, time = 0 })
		L(15, 5)
		for _, a in ipairs({ A.KhachA, A.KhachB, A.KhachC, A.KhachD, Linh, Ban }) do
			Kit.gaze(a, 0, -1)
			Kit.expr(a, "sad")
		end
		Kit.cam({ pos = P(0, 1.5, -6), look = P(0, 6, 4), mm = 24, time = 0 })
		L(15, 6, function()
			Kit.tw(s, 5, { MoonAngularSize = 6 })
		end)
		L(15, 7)
		for _, l in ipairs(lanterns) do
			l:Destroy()
		end
		s.MoonAngularSize = 11
	end

	-- 16 · NGÀY 7: TRỌNG LỰC TRỞ LẠI
	CH[16] = function()
		chapterCard("NGÀY 7")
		fallScene(16, 1, 2)
		Kit.cam({ pos = P(-14, 9, -24), look = P(0, 2, 2), mm = 24, time = 0 })
		L(16, 3)
		ctx.thermo.Enabled = true
		ctx.thermo:FindFirstChildOfClass("TextLabel").Text = "100°C"
		Kit.cam({ pos = P(10, 7.5, -34), look = P(15, 4.4, -28.5), mm = 35, time = 0, dof = 0.4, focusRadius = 2 })
		L(16, 4)
		ctx.thermo.Enabled = false
		ctx.thermo:FindFirstChildOfClass("TextLabel").Text = "81°C"
		Kit.cam({ pos = P(0, 3, -30), look = P(0, 60, 40), mm = 22, time = 0 })
		L(16, 5)
		L(16, 6)
		local sp = need("space")
		sp.setEscape(3)
		sp.drawOrbit(245, 891)
		Kit.look("night")
		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then
			atm.Density = 0
		end
		Kit.cam({ pos = sp.X(0, 650, -1), look = sp.X(0, 0, 0), mm = 16, time = 0, occlude = false })
		L(16, 7, function()
			for k = 0, 60 do
				local th = k / 60 * math.pi * 2
				local a, e = 568, 0.57
				local r = a * (1 - e * e) / (1 + e * math.cos(th)) * 0.7
				sp.moon.CFrame = CFrame.new(sp.X(r * math.cos(th), 0, r * math.sin(th)))
				task.wait(0.09)
			end
		end)
	end

	-- 17 · MỘT NĂM SAU
	CH[17] = function()
		Kit.look("morning")
		ctx.setGravity(1)
		ctx.placeCrowd()
		showOnly({ Ban, A.KhachA, A.KhachB, Linh, Tuan })
		chapterCard("1 NĂM SAU")
		Kit.cam({ pos = P(-30, 16, -40), look = P(0, 2, 10), mm = 24, time = 0 })
		L(17, 1)
		Kit.cam({ pos = P(0, 30, -60), look = P(0, 0, 0), mm = 24, time = 0 })
		L(17, 2, function()
			task.wait(2)
			fx("big", "Rằm tháng Tám\nrơi vào ngày nào?", 3)
		end)
		Kit.look("night")
		Lighting.ClockTime = 0
		local s = sky()
		s.MoonAngularSize = 11
		lookAtMoon(P(0, 3, -20), 35)
		L(17, 3, function()
			Kit.tw(s, 2.5, { MoonAngularSize = 17 })
			task.wait(3)
			Kit.tw(s, 2.5, { MoonAngularSize = 5 })
		end)
		Kit.look("afternoon")
		Lighting.ClockTime = 12
		s.MoonAngularSize = 7
		Kit.cam({ pos = P(0, 3, -20), look = P(0, 3, -20) + Lighting:GetSunDirection() * 200, mm = 50, time = 0, occlude = false, drift = 0 })
		L(17, 4)
		s.MoonAngularSize = 11
		local se = need("sea")
		Kit.look("morning")
		Kit.cam({ pos = se.B(-40, 10, -40), look = se.B(0, 2, 0), mm = 26, time = 0 })
		L(17, 5)
		Kit.cam({ pos = P(0, 30, -60), look = P(0, 0, 0), mm = 24, time = 0 })
		L(17, 6)
		L(17, 7, function()
			task.wait(1)
			fx("big", "Đáp án: C — Bầu trời", 3)
		end)
	end

	-- 18 · KẾT
	CH[18] = function()
		Kit.look("morning")
		ctx.placeCrowd()
		showOnly({ Ban, A.KhachA, A.KhachB, A.KhachC, A.KhachD, Linh, Tuan, A.CoBanMi })
		Kit.cam({ pos = P(-14, 9, -24), look = P(0, 2, 2), mm = 24, time = 0 })
		task.wait(0.05)
		Kit.cam({ pos = P(-24, 20, -40), look = P(0, 2, 2), mm = 24, time = 6 })
		L(18, 1, function()
			for i, a in ipairs(ctx.crowd) do
				task.delay(i * 0.3, function()
					Kit.pose(a, "wave", 0.3, false)
				end)
			end
		end)
		L(18, 2)
	end

	------------------------------------------------------------------ CHẠY
	fx("start")
	fx("fade", 1, 0)
	task.wait(0.2)
	fx("fade", 0, 0.4)
	local from, to = 1, #CH
	if CHUONG > 0 then
		from, to = CHUONG, CHUONG
	end
	for c = from, to do
		local ok, err = pcall(CH[c])
		if not ok then
			warn("[VideoDai] Lỗi ở chương " .. c .. ": ", err)
		end
		fx("line", "", "")
		task.wait(0.6)
	end
	fx("fade", 1, 1)
	task.wait(1.2)
	workspace.Gravity = ctx.oldGravity
	fx("end")
end

return VD
