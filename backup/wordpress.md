#slider_apple, #slider_google, .appStoreClass, .googlePlayClass {
    visibility: hidden;
}

function isMobile() {
    return /iphone|ipod|ipad|ipad|Android|nokia|blackberry|webos|webos|webmate|bada|lg|ucweb|skyfire|sony|ericsson|mot|samsung|sgh|lg|philips|panasonic|alcatel|lenovo|cldc|midp|wap|mobile/i.test(navigator.userAgent.toLowerCase());    
}

function getQueryString(name) {
　　var reg = new RegExp("(^|\\?|&)"+ name +"=([^&]*)(\\s|&|$)", "i");
　　if (reg.test(location.href)) {
    　　return unescape(RegExp.$2.replace(/\+/g, " "));
    }
　　return "";
}

function setCookie(cname,cvalue,exdays) {
    var d = new Date();
    d.setTime(d.getTime()+(exdays*24*60*60*1000));
    var expires = "expires="+d.toGMTString();
    document.cookie = cname + "=" + cvalue + "; " + expires;
}

function getCookie(cname) {
    var name = cname + "=";
    var ca = document.cookie.split(';');
    for(var i = 0; i < ca.length; i++) {
        var c = ca[i].trim();
        if (c.indexOf(name) == 0) {
            return c.substring(name.length,c.length);
        }
    }
    return "";
}

function getHostName(url) {
    var match = url.match(/:\/\/(www[0-9]?\.)?(.[^/:]+)/i);
    if (match != null && match.length > 2 && typeof match[2] === 'string' && match[2].length > 0) {
    return match[2];
    }
    else {
        return null;
    }
}

jQuery(document).ready(function($) {
    function replaceLink2QRCode(storeUrl, qrCodeUrl) {
        var leftStr = "10%;";
        /* if("ios" == type) {
            $(".appStoreClass").attr("href", storeUrl).removeClass("x-anchor").html("<img height=\"100\" width=\"100\" style=\"position: relative; top: -10px; left: "+leftStr+"\" src='"+qrCodeUrl+"' />").css({visibility: "visible"});
        } else if("android" == type) {
            $(".googlePlayClass").attr("href", storeUrl).removeClass("x-anchor").html("<img height=\"100\" width=\"100\" style=\"position: relative; top: -10px\" src='"+qrCodeUrl+"' />").css({visibility: "visible"});
        } */
        $(".appStoreClass").attr("href", storeUrl).removeClass("x-anchor").html("<img height=\"100\" width=\"100\" style=\"position: relative; top: -10px; left: "+leftStr+"\" src='"+qrCodeUrl+"' />").css({visibility: "visible"});
    }
    function show() {
        $("#slider_apple, #slider_google, .appStoreClass, .googlePlayClass").css({visibility: "visible"});
    }
    try {
        // ?utm_campaign=xwallet_youtube_xwtvc&utm_medium=video&utm_source=youtube
        var url = window.location.href;
        var referrer = document.referrer;
        var cookieName = "www_zerofinance_hk_campaign";
        var exdays = 7;
        // console.info("referrer--->", referrer);
        // var search = window.location.search;
        var utmCampaign = "";
        var utmMedium = "";
        var utmSource = "";
        if(url.indexOf("utm_campaign") != -1) {
            utmCampaign = getQueryString("utm_campaign");
            if(url.indexOf("utm_medium") != -1) {
                utmMedium = getQueryString("utm_medium");
            }
            if(url.indexOf("utm_source") != -1) {
                utmSource = getQueryString("utm_source");
            }
            var cookieValue = utmCampaign+"/"+utmMedium+"/"+utmSource;
            setCookie(cookieName, cookieValue, exdays);
        } else if(referrer && referrer.indexOf("www.zerofinance.hk") != -1) {
            // from self
            var cookieValue = getCookie(cookieName);
            if(cookieValue != "") {
                var utmCampaigns = cookieValue.split("/");
                utmCampaign = utmCampaigns[0];
                utmMedium = utmCampaigns[1];
                utmSource = utmCampaigns[2];
            }
        } else if(referrer) {
            var campaign = getHostName(referrer);
            // search from others
            utmCampaign = campaign;
            utmMedium = "referral";
            utmSource = "website";
            var cookieValue = utmCampaign+"/"+utmMedium+"/"+utmSource;
            setCookie(cookieName, cookieValue, exdays);
        } else {
            // direct
            utmCampaign = "direct";
            utmMedium = "direct";
            utmSource = "website";
            setCookie(cookieName, "", exdays);
        }

        // console.info("utmCampaign--->", utmCampaign);
        // console.info("utmMedium--->", utmMedium);
        // console.info("utmSource--->", utmSource);
        if(utmCampaign != "") {
            var appStoreUrl = "https://itunes.apple.com/hk/app/id1276449806";
            var googlePlayUrl = "https://play.google.com/store/apps/details?id=zero.finance.instantcash";

            var requestUrl = "https://xwallet.zerofinance.hk/api/system/getShortLink";
            var qrcodeUrl = "https://xwallet.zerofinance.hk/api/system/getQRCode";
            // the code be allowed user to the app store and google play store with the same shorturl
            var ajaxAppStoreUrl = requestUrl+"?link="+encodeURI(appStoreUrl)+"&campaign="+utmCampaign+"&medium="+utmMedium+"&source="+utmSource;
            $.get(ajaxAppStoreUrl,function(result){
                var storeUrl = result.data;
                // console.info("appStoreUrl--->", storeUrl);
                if(!isMobile()) {
                    // for pc
                    var appStoreQRCodeUrl = qrcodeUrl+"?txt="+encodeURI(storeUrl);
                    replaceLink2QRCode(storeUrl, appStoreQRCodeUrl);
                } else {
                    // for mobile
                    $(".appStoreClass").attr("href", storeUrl).css({visibility: "visible"});
                }
                try {$("#slider_apple").attr("href", storeUrl).css({visibility: "visible"});}catch(err){}
            }).fail(function() {
                show();
            });

            // Only for google play store on the mobile
            var ajaxGooglePlayUrl = requestUrl+"?link="+encodeURI(googlePlayUrl)+"&campaign="+utmCampaign+"&medium="+utmMedium+"&source="+utmSource;
            $.get(ajaxGooglePlayUrl,function(result){
                var storeUrl = result.data;
                if(isMobile()) {
                    $(".googlePlayClass").attr("href", storeUrl).css({visibility: "visible"});
                }
                try {$("#slider_google").attr("href", storeUrl).css({visibility: "visible"});}catch(err){}
            }).fail(function() {
                show();
            });
        } else {
            show();
        }
    } catch(err) {
        show();
        // console.error("error--->", err);
    }
});

// https://www.zerofinance.hk/zh/x/#/content/6262/layout
// https://www.zerofinance.hk/zh/x/#/content/6146/layout
// https://www.zerofinance.hk/en/x/#/content/6266/inspector?lang=en
// https://www.zerofinance.hk/en/x/#/content/6156/inspector?lang=en

// Zero Finance – 主頁 — Front Page
// 保留
// https://www.zerofinance.hk/zh/

// Zero Finance – 主頁
// 删除
// https://www.zerofinance.hk/zh/zero-finance-%e4%b8%bb%e9%a0%81-2/

// X Wallet Loan – Direct
// 保留
// https://www.zerofinance.hk/zh/x-wallet-loan/

// X Wallet Loan – Facebook
// 删除
// https://www.zerofinance.hk/zh/x-wallet-loan-fb/

// X Wallet Loan – GDN
// 删除
// https://www.zerofinance.hk/zh/x-wallet-loan-gdn/

// X Wallet Loan – Google
// 删除
// https://www.zerofinance.hk/zh/x-wallet-loan-google/

// X Wallet Loan – ViuApp
// 删除
// https://www.zerofinance.hk/zh/x-wallet-loan-viuapp/

// X Wallet Loan – Direct
// 保留
// https://www.zerofinance.hk/en/x-wallet-loan/

// Zero Finance – Homepage — Front Page
// 保留
// https://www.zerofinance.hk/en/

// Zero Finance – Homepage — Draft
// 删除
// https://www.zerofinance.hk/en/?page_id=7227&preview=true