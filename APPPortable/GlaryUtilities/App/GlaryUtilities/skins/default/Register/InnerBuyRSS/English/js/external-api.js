// JavaScript Document
//界面和后台程序交互接卿
//OperationType:操作类型
//strParam:参数，多参数之间可以用约定分隔符进行传辿
/*
BEGIN_DISPATCH_MAP(CBuyWizardWebDlg, CDHtmlDialog)
DISP_FUNCTION(CBuyWizardWebDlg,"CloseWindow",CloseWindowFromWeb,VT_EMPTY,VTS_NONE)
DISP_FUNCTION(CBuyWizardWebDlg,"OpenURL",OpenURLForDefalutBrowser,VT_BOOL,VTS_BSTR VTS_BSTR)
END_DISPATCH_MAP()
*/
/*
CloseWindow
关闭窗口，具体操作由客户端执行
*/
function CloseWindow()
{
	try{
		return window.external.CloseWindow();
	   }
	catch(e)
	   {
		  //alert("Call UItoBackApp faild!" + e);//调用失败时弹出该对话框提碿
	   }
}
/*
OpenURL
用默认浏览器打开指定网址，客户端会附加特有的参数在链接后面
url:网址
param:附加参数，暂时用不上
*/
function OpenURL(url,param)
{
	try{
		return window.external.OpenURL(String(url),String(param));
	   }
	catch(e)
	   {
		  //alert("Call UItoBackApp faild!" + e);//调用失败时弹出该对话框提碿
	   }
}
