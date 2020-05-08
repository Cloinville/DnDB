$(document).ready(function(){
    $("#add").click(function(e){
        event.preventDefault()
        $('#items').append('<div><input type="text" name="user-name"><input type="text" name="user-email">'+'<input type="button" value="delete" id="delete"></div>');
    });

    $('body').on('click', '#delete', function(e){
        $(this).parent('div').remove();
    });
});