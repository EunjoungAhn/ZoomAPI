# ZoomAPI
### Zoom은 Api와 SDK를 제공해줍니다. 
### 좀 더 커스텀을 위해서는 SDK를 zoom market place에서 만들어서 키를 발급받아 진행하고,   
### 또한 샘플 코드를 github에 제공하므로 참고하면 좋습니다.   
</br>
전 참고로 zoom api를 활용하여서 작업을 했습니다.   
</br>
C# zoom api, meeting create 관련

```C#
//C# Asp.net Core 버전 입니다.
//zoom 미팅 생성 - 수업 예정인 강의seq, 수업을 진행할 강사의 seq, 수업 제목, zoom으로 회의를 개설한 zoom email
[Route("Api/Create/Zoom/meeting")] //인자로 받는 값은 zoom api에서 필요한 필수 값은 아니며, 사용자에게 받아서 적용하기 위해 추가 하였습니다.
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


#Zoom api Personal Test code
```C#
[Route("Api/ZoomTest")]
public JsonResult ZoomTest()
{
    var result = new ReturnValue();
    //zoom 회의 참석자 기록 가져오기
    /*
    var participants = "https://api.zoom.us/report/meetings/" + zoomId + "/participants";
    var ParticipantsRequest = new RestRequest(Method.GET);
    Logger.Current.Debug($"JParticipants : {JParticipants}");
    */


    //회의 기록 관련 Test

    //토큰 만들기

    var tokenHandler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
    var now = DateTime.UtcNow;
    var apiSecret = "";
    byte[] symmetricKey = Encoding.ASCII.GetBytes(apiSecret);
    var tokenDescriptor = new SecurityTokenDescriptor
    {
        //App credentials > API Key 값 입니다.
        Issuer = "",//lsk
        Expires = now.AddSeconds(300),
        SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(symmetricKey), SecurityAlgorithms.HmacSha256),
    };
    var token = tokenHandler.CreateToken(tokenDescriptor);
    var tokenString = tokenHandler.WriteToken(token);

    var zoomTest = new RestClient("https://api.zoom.us/v2/accounts/{accountId}/report/activities");
    var request = new RestRequest(Method.GET);
    request.AddHeader("content-type", "application/json");
    //request.AddHeader("authorization", "Bearer 39ug3j309t8unvmlmslmlkfw853u8");
    request.AddHeader("authorization", String.Format("Bearer {0}", tokenString));
    IRestResponse response = zoomTest.Execute(request);

    var jObject = JObject.Parse(response.Content);
    Logger.Current.Debug($"jObject : {jObject}");

    return Json(result);
}
```

#Zoom api user정보 가져오는 code
```C#
[Route("Api/ZoomTest")]
public JsonResult ZoomTest()
{
    var result = new ReturnValue();
    var tokenHandler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
    var now = DateTime.UtcNow;
    var apiSecret = "";
    byte[] symmetricKey = Encoding.ASCII.GetBytes(apiSecret);
    var tokenDescriptor = new SecurityTokenDescriptor
    {
        Issuer = "",
        Expires = now.AddSeconds(300),
        SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(symmetricKey), SecurityAlgorithms.HmacSha256),
    };
    var token = tokenHandler.CreateToken(tokenDescriptor);
    var tokenString = tokenHandler.WriteToken(token);

    var zoomTest = "https://api.zoom.us/v2/users/{userID}";//To find your master account ID
    var request = new RestRequest(Method.GET);
    request.AddHeader("content-type", "application/json");
    request.AddHeader($"authorization", $"Bearer {tokenString}");
    //request.AddHeader("authorization", String.Format("Bearer {0}", tokenString));
    IRestResponse response = zoomTest.Execute(request);

    var jObject = JObject.Parse(response.Content);
    Logger.Current.Debug($"jObject : {jObject}");

    return Json(result);
}
```

#Zoom api 회의 참여 기록 가져오는 code
```C#
[Route("Api/ZoomTest")]
public JsonResult ZoomTest()
{
    var result = new ReturnValue();
    //회의 기록 가져오기 - get 형식
    var zoomTest = "https://api.zoom.us/v2/report/meetings/{meetingId}/participants";// 3월19일 회의 기록
    var test = new RestClient(zoomTest);
    var request = new RestRequest(Method.GET);
    request.AddHeader("content-type", "application/json");
    request.AddHeader($"authorization", $"Bearer {Tokten}");
    IRestResponse response = test.Execute(request);

    var jObject = JObject.Parse(response.Content);
    Logger.Current.Debug($"jObject : {jObject}");
    return Json(result);
}
```

#Zoom api - Response :{“code”:124,“message”:“The Token can’t be used before.. 관련 에러 함수
```C#
public static string ZoomToken()
{
// Token will be good for 20 minutes
DateTime Expiry = DateTime.UtcNow.AddMinutes(20);

string ApiKey = ConfigurationManager.AppSettings["ClientIdJwt"];
string ApiSecret = ConfigurationManager.AppSettings["ClientSecretJwt"];

int ts = (int)(Expiry - new DateTime(1970, 1, 1)).TotalSeconds;

// Create Security key  using private key above:
var securityKey = new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(Encoding.UTF8.GetBytes(ApiSecret));

// length should be >256b
var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

//Finally create a Token
var header = new JwtHeader(credentials);

//Zoom Required Payload
var payload = new JwtPayload
{
      { "iss", ApiKey},
      { "exp", ts },
};

var secToken = new JwtSecurityToken(header, payload);
var handler = new JwtSecurityTokenHandler();

// Token to String so you can use it in your client
var tokenString = handler.WriteToken(secToken);

      return tokenString;
}
```

#Zoom api - Response :{“code”:124,“message”:“The Token can’t be used before.. 관련 에러 해결 code -> JWT Token
```C#
    //바꾸어서 작동되는 JWT Token : S

    // Token will be good for 20 minutes
    DateTime Expiry = DateTime.UtcNow.AddMinutes(20);

    string ApiKey = "v0vTy-YqSx-Xtvb8QAFJzA";
    string ApiSecret = "x041Y6ifuyrPrVkmzauay1ORhR4ekAQRJpeg";

    int ts = (int)(Expiry - new DateTime(1970, 1, 1)).TotalSeconds;

    // Create Security key  using private key above:
    var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(ApiSecret));

    // length should be >256b
    var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

    //Finally create a Token
    var header = new JwtHeader(credentials);

    //Zoom Required Payload
    var payload = new JwtPayload
    {
        { "iss", ApiKey},
        { "exp", ts },
    };

    var secToken = new JwtSecurityToken(header, payload);
    var handler = new JwtSecurityTokenHandler();

    // Token to String so you can use it in your client
    var tokenString = handler.WriteToken(secToken);

    //바꾸어서 작동되는 JWT Token : E 
```
