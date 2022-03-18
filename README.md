# ZoomAPI
C# zoom api, meeting create 관련

```C#
//C# Asp.net Core 버전 입니다.
//zoom 미팅 생성 - 수업 예정인 강의seq, 수업을 진행할 강사의 seq, 수업 제목, zoom으로 회의를 개설한 zoom email
[Route("Api/Create/Zoom/meeting")]
public JsonResult ZoomMeetingCreateUpdate(string LectureSeq, string AccountSeq, string LectureTitle, string UserId)
{
    var result = new ReturnValue();
    //zoom api로 받아오는 값을 담기 위한 class
    var zoomResult = new ZoomResult();

    if (this.IsLogin)
    {
        //NuGet Packages에서 System.IdentityModel.Tokens.Jwt를 받아 설치합니다.
        //zoom에서는 2가지 인증이 있습니다.
        //두 가지 인증 방식인 OAuth 2.0, JWT 중 JWT로 인증을 받았습니다.
        var tokenHandler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
        //날짜값 받기위한 변수
        var now = DateTime.UtcNow;
        //zoom 개발자 페이지의 App Marketplace에서 JWT 클릭 > App credentials >
        //API Secret값 입니다.
        var apiSecret = "";//ej
        //아스키 코드 값으로 변환
        byte[] symmetricKey = Encoding.ASCII.GetBytes(apiSecret);

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            //App credentials > API Key 값 입니다.
            Issuer = "",
            Expires = now.AddSeconds(300),
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(symmetricKey), SecurityAlgorithms.HmacSha256),
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        var tokenString = tokenHandler.WriteToken(token);

        /*
        NuGet Packages에서 RestSharp 최신버전이 아닌 106.11.7을 받습니다.
        사용자의ID값을 넣어줍니다.https://api.zoom.us/v2/users/사용자의아이디/meetings"
        만약 userId를 넣어도 'code: 1001' 값이 확인 된다면, zoom 유료계정 관리자 메뉴에서 사용자를 추가해 주어야 합니다.
        */

        //var client = new RestClient("https://api.zoom.us/v2/users/dev@exmaru.com/meetings");
        //var UserId = "";
        var createZoom = "https://api.zoom.us/v2/users/"+ UserId + "/meetings";
        var client = new RestClient(createZoom);
        var request = new RestRequest(Method.POST);
        request.RequestFormat = DataFormat.Json;

        //교육 제목 변수
        var lectureTitle = LectureTitle;
        request.AddJsonBody(new { topic = lectureTitle, duration = "20", start_time = DateTime.Now.ToString(), type = "1" });//type=1은 공개, 2 = 암호가 필요한 방이 생성 됩니다.

        request.AddHeader("authorization", String.Format("Bearer {0}", tokenString));
        IRestResponse restResponse = client.Execute(request);
        //zoom api 코드 결과 코드
        //HttpStatusCode statusCode = restResponse.StatusCode;
        //var numericStatusCode = (int)statusCode; //Response Code
        //var Code = Convert.ToString(numericStatusCode);

        //값 받는 곳
        var jObject = JObject.Parse(restResponse.Content);
        var zoomId = (string)jObject["id"]; //2
        var zoomEmail = (string)jObject["host_email"]; //4
        var startUrl = (string)jObject["start_url"]; //12
        var joinUrl = (string)jObject["join_url"]; //13

        //zoom에서 넘겨주는 json 값을 찍어 확인하는 로그입니다.
        Logger.Current.Debug($"jObject : {jObject}");
        //Logger.Current.Debug($"startUrl : {startUrl}");
        //Logger.Current.Debug($"joinUrl : {joinUrl}");
        zoomResult.zoomId = zoomId;
        zoomResult.zoomEmail = zoomEmail;
        zoomResult.startUrl = startUrl;
        zoomResult.joinUrl = joinUrl;

        //zoom 테이블에 insert
        result = this.Db.ZoomMeetingCreate(LectureSeq, AccountSeq, zoomResult);
    }
    else
    {
        result.Error("로그인 후 이용해 주세요.");
    }

    return Json(zoomResult);
}
```