<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Create.aspx.cs" Inherits="ZoomAPI.Create" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <div>
            <h2>Host URL</h2>
            <asp:Label ID="Host" runat="server" Text="Link"></asp:Label>
            <h2>Join URL</h2>
            <asp:Label ID="Join" runat="server" Text="Link"></asp:Label>
            <h2>Response Code</h2>
            <asp:Label ID="Code" runat="server" Text="Code"></asp:Label>
            <br />
            <br />
            <asp:Button ID="Button1" runat="server" Text="Create" OnClick="Button1_Click" />
        </div>
    </form>
</body>
</html>
