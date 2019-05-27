<script type="text/javascript" src="http://ajax.microsoft.com/ajax/jquery/jquery-1.8.3.min.js"></script>
<script type="text/javascript">
    !window.jQuery && document.write("<script src='http://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js'><\/script>");
</script>
<script type="text/javascript">
    function isMobile(){
        return /iphone|ipod|ipad|ipad|Android|nokia|blackberry|webos|webos|webmate|bada|lg|ucweb|skyfire|sony|ericsson|mot|samsung|sgh|lg|philips|panasonic|alcatel|lenovo|cldc|midp|wap|mobile/i.test(navigator.userAgent.toLowerCase());    
    }
    $(function() {
        var referrer = document.referrer;
        //$(document.body).append("<div id='imgId'></div>");
        $("#imgId").html("<img src='http://img1.imgtn.bdimg.com/it/u=848059502,1900888847&fm=26&gp=0.jpg' />");
        $.get("http://yapi.zerofinance.net/mock/33/api/user/getLoginUser",function(data, status){
            $("#imgId").append("<br/>referrer: "+referrer+"<br/>Data: " + data)
        });
    });

    if(!isMobile()){
        alert("显示桌面版网站内容");
    } else {
        alert("显示移动版网站内容");
    }
</script>