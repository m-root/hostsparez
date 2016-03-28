// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//


//= require jquery
//= require jquery_ujs
//= require modernizr-2.6.2.min
//= require sliding
//= require scripts
//= require zipy_plugins
//= require ziply_main
//= require jquery.form
//= require jquery.ui.core
//= require jquery.ui.fancybox

//= require jquery.geocomplete
//= require apprise-1.5.full
//= require jquery.validate.min
//= require underscore-min
//= require jqueryeasydropdown
//= require jquery.maskedinput
//= require fast-live-filter
//= require jquery-ui
//= require jquery-ui-timepicker-addon
//= require chosen.jquery
//= require easyResponsiveTabs
//= require detect_timezone
//= require jquery.detect_timezone
//


function file_a_claim() {
    $("#ajax_loader").show();
    $(".shadow").show();
    $.ajax({
        url: '/customer/file_claims/new',
        type: 'get',
        dataType: 'html',
        processData: false,
        success: function (data) {
            $("#pop_up_div").html(data);
            $("#ajax_loader").hide();
            $(".shadow").hide();
            $("html, body").animate({ scrollTop: 0 }, "slow");
        }
    });
}


function get_call(e, obj) {
    $('#pop_up_div').css("display", "none");
    $("#ajax_loader").show();
    $.ajax({
        type: "GET",
        url: $(obj).attr('href'),
        error: function (jqXHR, textStatus) {
            $("#ajax_loader").hide();
            hudMsg("error", "Something went wrong please try later");
        },
        success: function (response) {
            $("#ajax_loader").hide();
            $('#pop_up_div').html(response).fadeIn('slow');
            $("html, body").animate({ scrollTop: 0 }, "slow");
        }
    });
    return e.preventDefault();
}


$(function () {
    $('.my-fancy-box').click(function (e) {
        $('#pop_up_div').css("display", "none");
        $("#ajax_loader").show();
        e.preventDefault();
        $.ajax({
            type: "GET",
            url: $(this).attr('href'),
            error: function (jqXHR, textStatus) {
                $("#ajax_loader").hide();
                hudMsg("error", "Something went wrong please try later");
            },
            success: function (response) {
                $("#ajax_loader").hide();
                $('#pop_up_div').html(response).fadeIn('slow');
                $("html, body").animate({ scrollTop: 0 }, "slow");
            }
        });
    });
});


function hudMsg(type, message, timeOut) {

    $('.hudmsg').remove();

    if (!timeOut) {
        timeOut = 3000;
    }

    var timeId = new Date().getTime();

    if (type != '' && message != '') {
        $('<div class="hudmsg ' + type + '" id="msg_' + timeId + '"><img src="/assets/msg_' + type + '.png" alt="" />' + message + '</div>').hide().appendTo('body').fadeIn();

        var timer = setTimeout(
            function () {
                $('.hudmsg#msg_' + timeId + '').fadeOut('slow', function () {
                    $(this).remove();
                });
            }, timeOut
        );
    }
}


(function ($) {
    if (!$.setCookie) {
        $.extend({
            setCookie: function (c_name, value, exdays) {
                try {
                    if (!c_name) return false;
                    var exdate = new Date();
                    exdate.setDate(exdate.getDate() + exdays);
                    var c_value = escape(value) + ((exdays == null) ? "" : "; expires=" + exdate.toUTCString());
                    document.cookie = c_name + "=" + c_value;
                }
                catch (err) {
                    return false;
                }
                ;
                return true;
            }
        });
    }
    ;
    if (!$.getCookie) {
        $.extend({
            getCookie: function (c_name) {
                try {
                    var i, x, y,
                        ARRcookies = document.cookie.split(";");
                    for (i = 0; i < ARRcookies.length; i++) {
                        x = ARRcookies[i].substr(0, ARRcookies[i].indexOf("="));
                        y = ARRcookies[i].substr(ARRcookies[i].indexOf("=") + 1);
                        x = x.replace(/^\s+|\s+$/g, "");
                        if (x == c_name) return unescape(y);
                    }
                    ;
                }
                catch (err) {
                    return false;
                }
                ;
                return false;
            }
        });
    }
    ;
})(jQuery);
