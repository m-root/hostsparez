# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
#  window._gaq = [
#    ["_setAccount", "UAXXXXXXXX1"],
#    ["_trackPageview"],
#    ["_trackPageLoadTime"]
#  ]
#  Modernizr.load load: ((if "https:" is location.protocol then "//ssl" else "//www")) + ".google-analytics.com/ga.js"

  $(document).ready ->
    setInterval (->
      $("#flash").fadeOut()
    ), 5000

#    placeholder = " "
#    $("input[type=text],input[type=email],input[type=password]").focus ->
#      placeholder = $(this).attr("placeholder")
#      $(this).attr "placeholder", " "
#
#    $("input[type=text],input[type=email],input[type=password]").blur ->
#      $(this).attr "placeholder", placeholder  if $(this).val() is ""

#    $(".datepicker").datepicker()

#    $(".autocomplete").autocomplete
#      source: (request, response) ->
#        $.ajax
#          url: "http://ws.geonames.org/searchJSON"
#          dataType: "jsonp"
#          data:
#            featureClass: "P"
#            style: "full"
#            maxRows: 12
#            name_startsWith: request.term
#
#          success: (data) ->
#            response $.map(data.geonames, (item) ->
#              label: item.name + ((if item.adminName1 then ", " + item.adminName1 else "")) + ", " + item.countryName
#              value: item.name + ((if item.adminName1 then ", " + item.adminName1 else "")) + ", " + item.countryName
#            )
#
#
#      minLength: 2
#      open: ->
#        $(this).removeClass("ui-corner-all").addClass "ui-corner-top"
#
#      close: ->
#        $(this).removeClass("ui-corner-top").addClass "ui-corner-all"

#    $(".login_btn").children("a").click ->
#      $(this).parents("form").submit()

    $('.fancybox').fancybox()