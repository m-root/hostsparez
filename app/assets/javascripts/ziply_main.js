!function (a) {
    "use strict";
    var b = "014593374506328066574:dlgoncf_usu", c = 51.514617, d = -.190359, e = {Android: function () {
        return navigator.userAgent.match(/Android/i)
    }, BlackBerry: function () {
        return navigator.userAgent.match(/BlackBerry/i)
    }, iOS: function () {
        return navigator.userAgent.match(/iPhone|iPad|iPod/i)
    }, Opera: function () {
        return navigator.userAgent.match(/Opera Mini/i)
    }, Windows: function () {
        return navigator.userAgent.match(/IEMobile/i)
    }, any: function () {
        return e.Android() || e.BlackBerry() || e.iOS() || e.Opera() || e.Windows()
    }};
    jQuery(document).ready(function (a) {
        if (a("input, textarea").placeholder(), a(".main_menu").attr("id", "menu"), selectnav("menu", {indent: "&nbsp;&nbsp;"}), a(".main_menu li").hover(function () {
            a(this).find("ul").first().stop(!0, !0).fadeIn(500)
        }, function () {
            a(this).find("ul").first().stop(!0, !0).fadeOut(500)
        }), a(".main_menu li, .down").click(function () {
            var b = a(this).attr("href");
            return void 0 === b && (b = a(this).find("a").attr("href")), b.indexOf("#") >= 0 && 0 !== a(b).length ? (a(".main_menu a").removeClass("current"), a(this).addClass("current"), a.smooth(b, -60), !1) : void(window.location = b)
        }), 0 === a(".solid").length) {
            var b = a(".main_menu").height();
            a(window).on("scroll", function () {
                var c = jQuery(window).scrollTop();
                c > b + 100 ? a(".header").addClass("solid") : a(".header").removeClass("solid")
            })
        }
        var c = function (b) {
            var c;
            b.each(function () {
                var b = a(this), d = b.data("animation");
                b.css({visibility: "hidden"}).removeClass("animated " + d), c = a(this).data("animate-delay"), void 0 === c && (c = "2000"), setTimeout(function () {
                    b.css({visibility: "visible"}).addClass("animated " + d)
                }, c)
            })
        };
        a(".main-slider").find(".cap-anim").css({visibility: "hidden"}), a(".main-slider").bxSlider({auto: !0, speed: 1e3, pause: 8e3, mode: "fade", pager: !1, controls: !1, onSliderLoad: function () {
            c(a(".main-slider").find("li").eq(0).find(".cap-anim"))
        }, onSlideBefore: function (a) {
            c(a.find(".cap-anim"))
        }, onSlideAfter: function () {
        }}), null === e.any() ? a(".player").mb_YTPlayer() : a(".slider-wrapper").addClass("video-placeholder"), a(".testimonial").bxSlider({auto: !0, speed: 1e3, pause: 8e3, mode: "fade", pager: !1, controls: !1}), a(".post-slider").bxSlider({auto: !0, speed: 1e3, pause: 8e3, mode: "fade", pager: !1, controls: !0}), a(".process-slider").bxSlider({auto: !0, speed: 1e3, pause: 6e3, mode: "fade", pager: !1, controls: !1, onSlideBefore: function (b, c, d) {
            a(".process-list li").removeClass("current").eq(d).addClass("current")
        }}), null === e.any() && a(".parallax").css("backgroundAttachment", "fixed").parallax("50%", .5, !0), null === e.any() ? a(".player").mb_YTPlayer() : a(".slider-wrapper").addClass("video-placeholder"), a("a[data-pp^='prettyPhoto']").prettyPhoto({hook: "data-pp", theme: "light_square", social_tools: ""}), a(".contact-form").contactValidation(), a(".accordian").accordian(), a(".tabs").tabs({type: "top"}), a(".sidetabs").tabs({type: "side"}), a(".toggle").toggle(), a(".alert-button").alerts(), a(".video-wrapper").fitVids(), a(".youtube iframe").each(function () {
            var b = a(this).attr("src");
            a(this).attr("src", b + "&wmode=transparent")
        }), a(".milestones").appear(function () {
            a(".count").each(function () {
                var b = a(this).data("count");
                a(this).countTo({from: 0, to: b, speed: 2200, refreshInterval: 60})
            })
        }), a("[data-hook=tooltip]").tipsy({gravity: "s", fade: !0}), a("[data-hook=tooltip]").trigger("mouseOver");
        var d = 4;
        a(".portfolio").waitForImages(function () {
            a(".portfolio").isotope({itemSelector: ".port-item", masonry: {columnWidth: a(".portfolio").width / 4}, animationEnigin: "best-availible", resizable: !1, filter: ".showme"})
        }), a(window).smartresize(function () {
            a(".portfolio").isotope({masonry: {columnWidth: a(".portfolio").width() / 4}})
        }), a("#load-more").click(function (b) {
            b.preventDefault(), d < a(".port-item").length && (d += 4), a(".port-item:lt(" + d + ")").addClass("showme"), a(".portfolio").isotope({filter: ".showme"}), d === a(".port-item").length && a(this).fadeOut()
        }), a(".filter-menu li").css({cursor: "pointer"}), a(".filter-menu li").trigger("click"), a(".filter-menu li").click(function () {
            if (!a(this).hasClass("selected")) {
                a(this).css("background")
            }
            a(this).fadeTo("background", "white"), a(this).siblings().removeClass("selected"), a(this).addClass("selected");
            var b = a(this).attr("data-cat"), c = ".isotope-item[data-cat=" + b + "]";
            "*" === b && (c = ".isotope-item"), a(".showme").removeClass("showme"), a(c + ":lt(" + d + ")").addClass("showme"), a(".portfolio").isotope({filter: ".showme"})
        });
        var f = function (b) {
            var c = a('<div class="project">' + b + "</div>").appendTo(".project-wrapper");
            h(), c.waitForImages(function () {
                i();
                var b = a(".project-wrapper"), c = a(".project").outerHeight() + 110;
                a(".project").css("height", "100%"), b.animate({height: c}, 600, function () {
                    b.css("height", "auto"), a(".project").fadeIn("slow"), b.find(".loader i").fadeOut()
                }), a(".project-wrapper").addClass("open"), a(".port-overlay .project-btn").removeClass("disabled")
            })
        }, g = function (b, c, d) {
            a.get(b.attr("href"), function (a) {
                d.resolve(a)
            }, "html")
        }, h = function () {
            a(".project-wrapper .container").prepend('<a href="#" class="close"><i class="fa fa-times-circle-o"></i></a>'), a(".project-wrapper .close").click(function () {
                return a(".project-wrapper").animate({height: 0}, function () {
                    a(".loader").fadeOut("slow", function () {
                        a(this).remove()
                    })
                }), a(".project-wrapper").removeClass("open"), a(".project").fadeOut("slow", function () {
                    a(".project").remove()
                }), !1
            })
        }, i = function () {
            a(".portfolio-slider").bxSlider({auto: !0, speed: 1e3, pause: 8e3, mode: "fade"})
        }, j = function (b) {
            a(".project-wrapper").css("height", a(".project-wrapper").outerHeight()), a(".project").fadeOut("slow", function () {
                a(".project").remove(), f(b)
            })
        }, k = function (a) {
            if (0 !== a.find(".loader").length)a.find(".loader i").fadeIn(); else {
                var b = '<div class="loader"><i class="fa fa-spinner spin"></i></div>';
                a.animate({height: 50}).prepend(b)
            }
        }, l = function (b) {
            var c = a(".project-wrapper"), d = a.Deferred(), e = a.Deferred();
            k(c), g(b, d, e), a.smooth(a(".loader"), -60, function () {
                d.resolve()
            }), a.when(e, d).done(function (a) {
                c.hasClass("open") ? j(a) : f(a)
            })
        };
        a(".port-overlay .project-btn").on("click", function (b) {
            b.preventDefault(), a(".port-overlay .project-btn").hasClass("disabled") || (a(".port-overlay .project-btn").addClass("disabled"), l(a(this)))
        });
        var m = function () {
            function b(a) {
                return document.createElementNS("http://www.w3.org/2000/svg", a)
            }

            var c, d = function (b, c, d, e) {
                for (var f, g, h = 1; b >= h; h += 1)g = d + c * Math.cos(2 * h * Math.PI / b + 11), f = void 0 === f ? Math.floor(g + 100) : f + ", " + Math.floor(g + 100), g = e + c * Math.sin(2 * h * Math.PI / b + 11), f = f + ", " + Math.floor(g + 100);
                return a(".notes").html(f), f
            }, e = 0;
            a(".feature-hex").each(function () {
                var b = a(this).find("img"), d = b.attr("src");
                b.remove(), c = '<svg class="svg-graphic" width="200" height="200" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1"><g><clipPath id="hex-mask' + e + '"></clipPath></g><image clip-path="url(#hex-mask' + e + ')" height="100%" width="100%" xlink:href="' + d + '" /></a></svg>', a(this).append(c), e++
            });
            var f = (a(".svg-graphic"), document.getElementsByTagName("svg")[0]), g = f.getAttribute("viewBox");
            g = g.split(" ");
            var h = 6, i = g[3] / 2 - 20, j = g[3] / 2 - 100, k = g[3] / 2 - 100, l = d(h, i, j, k);
            e = 0, a(".feature-hex").each(function () {
                var c = a("#hex-mask" + e);
                a(b("polygon")).attr("points", l).appendTo(c), e++
            }), h = 6, i = g[3] / 2 - 2, j = g[3] / 2 - 100, k = g[3] / 2 - 100;
            var m = d(h, i, j, k), n = a(".svg-graphic");
            a(b("polygon")).attr("points", m).attr("fill", "none").attr("stroke", "#d0d0d0").attr("stroke-width", 2).appendTo(n)
        };
        a(".feature-imgs").length && m()
    }), a(window).load(function () {
        a(".preloader").fadeOut("slow"), null === e.any() ? a(".animated").appear(function () {
            var b = a(this), c = b.data("animate-delay"), d = b.data("animate");
            void 0 === c && (c = "0"), setTimeout(function () {
                b.addClass(d).css("visibility", "visible"), b.addClass(d).find("i").css("visibility", "visible")
            }, c)
        }) : a(".animated").css("visibility", "visible").find("i").css("visibility", "visible");
        var b = function () {
            a(".skill-bar").easyPieChart({easing: "easeOutBounce", size: 140, animate: 2e3, lineWidth: 6, lineCap: "butt", barColor: "#bbb", trackColor: "#f0f0f0", scaleColor: !1, rotate: 270})
        };
        null === e.any() ? a(".skill-semi").appear(function () {
            setTimeout(function () {
                b()
            }, 1e3)
        }) : b(), a(".progress").each(function () {
            a(this).data("origWidth", a(this).width()).width(0)
        }), null === e.any() ? a(".progress").appear(function () {
            a(this).each(function () {
                a(this).animate({width: a(this).data("origWidth")}, 2e3)
            })
        }) : a(".progress").each(function () {
            a(this).css("width", a(this).data("origWidth"))
        });
        var f = function () {
            var b = a("#content").html(), e = [
                {featureType: "landscape", stylers: [
                    {saturation: -100},
                    {lightness: 65},
                    {visibility: "on"}
                ]},
                {featureType: "poi", stylers: [
                    {saturation: -100},
                    {lightness: 51},
                    {visibility: "simplified"}
                ]},
                {featureType: "road.highway", stylers: [
                    {saturation: -100},
                    {visibility: "simplified"}
                ]},
                {featureType: "road.arterial", stylers: [
                    {saturation: -100},
                    {lightness: 30},
                    {visibility: "on"}
                ]},
                {featureType: "road.local", stylers: [
                    {saturation: -100},
                    {lightness: 40},
                    {visibility: "on"}
                ]},
                {featureType: "transit", stylers: [
                    {saturation: -100},
                    {visibility: "simplified"}
                ]},
                {featureType: "administrative.province", stylers: [
                    {visibility: "off"}
                ]},
                {featureType: "water", elementType: "labels", stylers: [
                    {visibility: "on"},
                    {lightness: -25},
                    {saturation: -100}
                ]},
                {featureType: "water", elementType: "geometry", stylers: [
                    {hue: "#ffff00"},
                    {lightness: -25},
                    {saturation: -97}
                ]}
            ], f = new google.maps.LatLng(c, d), g = {zoom: 16, center: f, mapTypeId: google.maps.MapTypeId.ROADMAP, styles: e, scrollwheel: !1}, h = new google.maps.Map(document.getElementById("google-map"), g), i = new google.maps.MarkerImage("img/marker.png", null, null, null, new google.maps.Size(40, 52)), j = new google.maps.Marker({position: f, icon: i, map: h, title: "Click to visit our company on Google Places"}), k = new google.maps.InfoWindow({content: b});
            google.maps.event.addListener(j, "click", function () {
                k.open(h, j)
            }), a(".map-button").click(function (b) {
                b.preventDefault(), 0 === a(".map-wrapper").height() ? a(".map-wrapper").css("height", a("#google-map").height()) : a(".map-wrapper").css("height", 0)
            }), google.maps.event.addDomListener(window, "resize", function () {
                var a = h.getCenter();
                google.maps.event.trigger(h, "resize"), h.setCenter(a)
            })
        };
        a("#google-map").length && f(c, d)
    }), function () {
        if ("" !== b) {
            var a = b, c = document.createElement("script");
//            c.type = "text/javascript", c.async = !0, c.src = ("https:" == document.location.protocol ? "https:" : "http:") + "//www.google.com/cse/cse.js?cx=" + a;
//            var d = document.getElementsByTagName("script")[0];
//            d.parentNode.insertBefore(c, d)
        }
    }()
}(jQuery);

/*************************** Edited ***************************/


//$(".smal-nav").on("click", ".init", function () {
//    $(this).closest(".smal-nav").children('li:not(.init)').slideDown();
//});
//
//var allOptions = $(".smal-nav").children('li:not(.init)');
//$(".smal-nav").on("click", "li:not(.init)", function () {
//    allOptions.removeClass('selected');
//    $(this).addClass('selected');
//    $(".smal-nav").children('.init').html($(this).html());
//    allOptions.slideUp();
//});
//$(".smal-nav").click(function (e) {
//    e.stopPropagation();
//});
//$(document).click(function () {
//    $(".smal-nav").children('li:not(.init)').slideUp('fast');
//});
/***********************/
$(function () {

    $('#zdrp1').click(function () {
        $('#zdrp2').slideToggle('fast');
        return false;

    });
});

$(document).click(function () {
    $('#zdrp2').slideUp('fast');
});

$("#zdrp2").click(function (e) {
    e.stopPropagation();
});
/********************************/

$(function () {

    $('#zdrp11').click(function () {
        $('#zdrp22').slideToggle('fast');
        return false;

    });
});

$(document).click(function () {
    $('#zdrp22').slideUp('fast');
});

$("#zdrp22").click(function (e) {
    e.stopPropagation();
});
/***************************/

$(function () {

    $('#z_list1').click(function () {
        $('#z_list2').slideToggle('fast');
        return false;

    });
});

$(document).click(function () {
    $('#z_list2').slideUp('fast');
});

$("#z_list2").click(function (e) {
    e.stopPropagation();
});

/***************************/

$(function () {

    $('#z_list1-0').click(function () {
        $('#z_list2-0').slideToggle('fast');
        return false;

    });
});

$(document).click(function () {
    $('#z_list2-0').slideUp('fast');
});

$("#z_list2-0").click(function (e) {
    e.stopPropagation();
});


/***************** Edit Profile Photo Input type file ******************/
$("#uploadBtn").change(function() {
   $("#uploadFile").val(this.val());
});
//$(document).getElementById("uploadBtn").onchange = function () {
//    document.getElementById("uploadFile").value = this.value;
//};