$(document).ready(function(){
    // var attr_names_str = document.getElementById("attr_names").value;
    // // var field_type = document.getElementById("field_type").value;
    // var attr_names = attr_names_str.split(",");
    var i = 0;

    // var row_indices = {};
    // // row_indices['test'] = "Please"
    // // alert(row_indices['test'])
    // for (index = 0; index < attr_names.length; index++){
    //     var key = attr_names[index];
    //     row_indices[key] = 1;
    // }

    // var str = ""
    // for (var key in row_indices){
    //     var value = row_indices[key];
    //     alert(value);
    //     str = str + value + " - ";
    // }
    // alert(str)

    $('#add').click(function(){
        event.preventDefault();
        i++;

        var attr_adding = document.getElementById("add").value;
        var attr_adding_field_type_id = attr_adding + "_field_type";
        var input_field_type = document.getElementById(attr_adding_field_type_id).value

        if(input_field_type == "text"){

            // row_indices[attr_adding] += 1;
            // row_index = row_indices[attr_adding];

            $('#dynamic_field').append('<tr id="row'+i+'"><td><input type="text" name="'+attr_adding+'_'+i+'" id="'+attr_adding+'_'+i+'" placeholder="Enter" class="form-control name_list"></td><td><button name="remove" id="'+i+'" class="btn btn-danger btn_remove">X</button></td></tr>');
        }else{
            append_str = "";
            // '<tr id="row'+i+'"><td><input type="text" name="name[]" id="name" placeholder="Enter" class="form-control name_list"></td><td><button name="remove" id="'+i+'" class="btn btn-danger btn_remove">X</button></td></tr>'
            var selection = document.getElementById(attr_adding+"_options");
            for(var selection_index = 0; selection_index < selection.length; selection_index++){
                append_str += '<option value="' + selection[selection_index].value + '">' + selection[selection_index].text + '</option>';
            }
            $('#dynamic_field').append('<tr id="row'+i+'"><td><label for="'+attr_adding+'">'+attr_adding+' : </label><select id="'+attr_adding+'_'+i+'" name="'+attr_adding+'_'+i+'">'+append_str+'</select></td><td><button name="remove" id="'+i+'" class="btn btn-danger btn_remove">X</button></td></tr>');
        }
    });
    $(document).on('click', '.btn_add_dynamic_field', function(){
        var button_id = $(this).attr("id");
        var button_name = document.getElementById(button_id).name;
        event.preventDefault();
        i++;

        // var attr_adding = document.getElementById("add").value;
        var attr_adding = button_name;
        var attr_adding_field_type_id = attr_adding + "_field_type";
        var input_field_type = document.getElementById(attr_adding_field_type_id).value

        if(input_field_type == "text"){

            // row_indices[attr_adding] += 1;
            // row_index = row_indices[attr_adding];
            var html = '<tr id="row'+i+'"><td><input type="text" name="'+attr_adding+'_'+i+'" id="'+attr_adding+'_'+i+'" placeholder="Enter" class="form-control name_list"></td><td><button name="remove" id="'+i+'" class="btn btn-danger btn_remove">X</button></td></tr>';
            //$('#dynamic_field').append('<tr id="row'+i+'"><td><input type="text" name="'+attr_adding+'_'+i+'" id="'+attr_adding+'_'+i+'" placeholder="Enter" class="form-control name_list"></td><td><button name="remove" id="'+i+'" class="btn btn-danger btn_remove">X</button></td></tr>');
            var parent_row = $(this).closest('tr');
            $(html).insertBefore(parent_row);
        }else if(input_field_type == "select" || input_field_type == "multi"){
            append_str = "";
            // '<tr id="row'+i+'"><td><input type="text" name="name[]" id="name" placeholder="Enter" class="form-control name_list"></td><td><button name="remove" id="'+i+'" class="btn btn-danger btn_remove">X</button></td></tr>'
            var selection = document.getElementById(attr_adding+"_options");
            for(var selection_index = 0; selection_index < selection.length; selection_index++){
                append_str += '<option value="' + selection[selection_index].value + '">' + selection[selection_index].text + '</option>';
            }

            if(input_field_type == "select"){
                // $('#dynamic_field').append('<tr id="row'+i+'"><td><label for="'+attr_adding+'">'+attr_adding+' : </label><select id="'+attr_adding+'_'+i+'" name="'+attr_adding+'_'+i+'">'+append_str+'</select></td><td><button name="remove" id="'+i+'" class="btn btn-danger btn_remove">X</button></td></tr>');
                var html = '<tr id="row'+i+'"><td><select id="'+attr_adding+'_'+i+'" name="'+attr_adding+'_'+i+'">'+append_str+'</select></td><td><button name="remove" id="'+i+'" class="btn btn-danger btn_remove">X</button></td></tr>';
                var parent_row = $(this).closest('tr');
                $(html).insertBefore(parent_row);
            }else{
                var label_elem = document.getElementById(attr_adding+"_label");
                var label = "";
                if(label_elem != null){
                    label = label_elem.value + " : ";
                }
                //alert(attr_adding);

                var child_elem = document.getElementById(attr_adding+"_child");
                var child_name = child_elem.value;

                //alert(child_name);

                var child_label_elem = document.getElementById(child_name+"_label");
                var child_label = child_label_elem.value;

                var html = '<tr id="row'+i+'"><td><table class="inner_table"><tr><td><label for="'+attr_adding+'_'+i+'"name="'+attr_adding+'_'+i+'">'+label+'</label></td><td><select id="'+attr_adding+'_'+i+'" name="'+attr_adding+'_'+i+'">'+append_str+'</select></td></tr><tr><td><label for="'+child_name+'" name="'+child_name+'">'+child_label+'</label></td><td><table class="innermost_table"><tr><td colspan="2"><input type="button" name="'+child_name+'" id="'+child_name+'" value="+" class="btn_add_dynamic_field"></td></tr></table></td></tr></table></td><td><button name="remove" id="'+i+'" class="btn btn-danger btn_remove">X</button></td></tr>';
                var parent_row = $(this).closest('tr');

                $(html).insertBefore(parent_row);
            }
        }else{
            alert("Got an add for a non-addable type: " + input_field_type)
        }
        // alert("CLICKED: " + button_val + " - " + button_name);
    });
    $(document).on('click', '.btn_remove', function(){
        var button_id = $(this).attr("id");
        $('#row'+button_id+'').remove();
    });
});