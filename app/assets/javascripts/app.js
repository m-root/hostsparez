$(function () {
    $('.my-fancy-box').click(function (e) {
//        $('#pop_up_div').css("display", "none");
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
//                $('#pop_up_div').show();
            }
        });
    });
});


