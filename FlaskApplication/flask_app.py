from flask import Flask, render_template, request, redirect, url_for, session
# from flask_mysqldb import MySQL
import mysql.connector
import yaml
import re
import json

app = Flask(__name__)

# configure db
connection_values = yaml.load(open('db.yaml'))
logged_in_user_details = {'username': None, 'nickname': None, 'player_id': None, 'dm_id': None}
# logged_in_user = None
# logged_in_user_nickname = ""
default_dropdown_str = ""
searchable_entities = ['Monster', 'Class', 'Race', 'Spell', 'Item', 'Skill']
# creatable_entities = ['character', 'campaign', 'monster', 'item', 'weapon', 'spell', 'monsterparty']
creatable_entities = ['character', 'campaign', 'monsterparty']

# add try-except for db

@app.route('/login', methods=['GET', 'POST'])
def login():
    if logged_in_user_details['username'] != None:
        return redirect('/index')

    error = None
    # Post means have received submission from page
    if request.method == 'POST':
        db = connect()
        player_details = request.form

        cursor = db.cursor()

        cursor.execute("SELECT * FROM player WHERE player.player_username = '{0}' AND player.player_password = '{1}' LIMIT 1".format(player_details['username'], player_details['password']))

        result = cursor.fetchall()
        if len(result) > 0:
            player_login(player_details['username'])
            cursor.close()
            db.close()
            return redirect('/index')
        else:
            error = "Incorrect username or password. Please try again."

        cursor.close()
        db.close()

    return render_template('login.html', error=error)


@app.route('/signup', methods=['POST', 'GET'])
def signup():
    error = None
    # if logged_in_user != None:
    if logged_in_user_details['username'] != None:
        return redirect('/index')

    if request.method == 'POST':
        # trying to sign up
        player_details = request.form
        username = player_details['username']
        nickname = player_details['nickname']
        password = player_details['password']
        password_confirm = player_details['password_confirm']

        if len(username) == 0:
            error = "Username required"
        elif username_invalid(username):
            error = "Username can only contain alphanumerics and underscores. Please try again."
        else:
            db = connect()
            cursor = db.cursor()
            cursor.execute("SELECT * FROM player WHERE player.player_username = '{0}' LIMIT 1".format(username))
            result = cursor.fetchall()
            
            if len(result) > 0:
                error = "Username already exists. Please try again."

            elif username_invalid(nickname):
                error = "Nickname can only contain alphanumerics and underscores. Please try again."

            elif len(password) == 0:
                error = "Password required"

            elif password_invalid(password):
                error = "Password can only contain alphanumerics and underscores. Please try again."

            elif password != password_confirm:
                error = "Passwords don't match. Please try again"

            else:
                cursor.execute("INSERT INTO player(player_username, player_nickname, player_password) VALUES('{0}', '{1}', '{2}')".format(username, nickname, password))
                db.commit()
                player_login(username)
                return redirect('/index')
        
            cursor.close()
            db.close()
        
    return render_template('signup.html', error=error)


@app.route('/')
@app.route('/index')
def index():
    # if logged_in_user == None:
    if logged_in_user_details['username'] == None:
        return redirect('/login')
    return render_template('index.html',  logged_in_user_details=logged_in_user_details)


@app.route('/logout')
def logout():
    # global logged_in_user
    # global logged_in_user_nickname

    global logged_in_user_details
    logged_in_user_details['username'] = None
    logged_in_user_details['nickname'] = None
    logged_in_user_details['dm_id'] = None
    logged_in_user_details['player_id'] = None

    # logged_in_user = None
    # logged_in_user_nickname = None

    return redirect('/login')


#TODO: stub
@app.route('/profile', methods=['GET', 'POST'])
def profile():
    # if logged_in_user == None:
    if logged_in_user_details['username'] == None:
        return redirect('/login')

    error = None

    if request.method == 'POST':
        profile_details = request.form

        if profile_details["submit_btn"] == "Update":
            nickname = profile_details["nickname"]
            if username_invalid(nickname):
                error = "Nickname can only contain alphanumerics and underscores."
            else:
                update_player_nickname(nickname)

    return render_template('profile.html', error=error, logged_in_user_details=logged_in_user_details)


@app.route('/premium', methods=['GET', 'POST'])
def premium():
    if logged_in_user_details['username'] == None:
        return redirect('/login')

    if request.method == "POST":
        upgrade_player_to_dm()
        return redirect('/create')

    return render_template('premium.html', logged_in_user_details=logged_in_user_details)


@app.route('/my_campaigns', methods=['POST', 'GET'])
def my_campaigns():
    # if logged_in_user == None:
    if logged_in_user_details['username'] == None:
        return redirect('/login')

    # If campaign preview picked, send campaign_details the id of the selected campaign
    # to be used to generate the public/private details of that result
    if request.method == 'POST':        
        campaign_id = request.form['campaign_btn']
        return redirect(url_for('campaign_details', campaign_id=campaign_id))

    # Otherwise, render page with campaign previews
    campaign_preview_details = execute_cmd_and_get_result("CALL get_campaign_previews('{0}')".format(logged_in_user_details['username']))

    return render_template('my_campaigns.html', campaign_preview_details=campaign_preview_details, logged_in_user_details=logged_in_user_details)


# TODO: 4/25: actually implement
@app.route('/campaign_details')
def campaign_details():
    if logged_in_user_details['username'] == None:
        return redirect('/login')

    #TODO: add redirect for if have no campaign args?
    try:
        str_campaign_id=request.args.get('campaign_id')
        campaign_id = int(str_campaign_id)
    except:
        return redirect('/index')

    # 4-25 TODO: add actual fetch of campaign view
    # => DB-side: need to add procedure to fetch public OR private view,
    #    depending on whether/not are dm (full view of all),
    #    or are a player (view is dependent ON THAT PLAYER)

    #TODO: replace this, just a stub for now
    campaign_details = [campaign_id]

    return render_template('campaign_details.html', campaign_details=campaign_details, logged_in_user_details=logged_in_user_details)


#TODO: stub
@app.route('/my_creations', methods=['GET', 'POST'])
def my_creations():
    if logged_in_user_details['username'] == None:
        return redirect('/login')

    previews = []
    entities_to_show = []
    filterable_entities = [""]
    filter_entity = ""

    filterable_entities.extend(creatable_entities)

    if request.method == 'POST':
        # DEBUGGING
        for key in request.form:
            print("{0} : {1}".format(key, request.form[key]))

        # END DEBUGGING

        filter_entity = request.form['filter_entity']
        if filter_entity == "":
            entities_to_show.extend(creatable_entities)
        else:
            entities_to_show.append(filter_entity)
    else:
        entities_to_show.extend(creatable_entities)

    for entity in entities_to_show:
        results = execute_cmd_and_get_result("CALL get_previews_for_entity_created_by_player('{0}', '{1}')".format(logged_in_user_details['username'], entity))
        records_and_metadata = get_formatted_previews_and_metadata_list(results)
        if records_and_metadata != None:
            previews.append(records_and_metadata)

    entities_to_show.insert(0, "")

    # DEBUGGING
    print(previews)
    # END DEBUGGING
    return render_template('my_creations.html', filter_entity=filter_entity, filterable_entities=filterable_entities, entities_to_show=entities_to_show, previews=previews, logged_in_user_details=logged_in_user_details)


@app.route('/create')
def create():
    if logged_in_user_details['username'] == None:
        return redirect('/login')

    return render_template('create.html', logged_in_user_details=logged_in_user_details)


#TODO: stub
@app.route('/create_details/<entity>', methods=['GET', 'POST'])
def create_details(entity):
    if logged_in_user_details['username'] == None:
        return redirect('/login')

    if request.method == "POST":
        if request.form['submit_btn'] == "Quit":
            return redirect('/index')
        else:
            in_entity_field_values = []
            raw_multi_level_associative_metadata = []
            single_level_associations = []
            # associative_multi_parents = []
            # associative_multi_children = []
            # Probably not necessary for our current implementation \/
            multi_level_associations_parents_to_children = {}
            chosen_entity = request.form["chosen_entity"]

            for key in request.form:
                print("{0}, {1}".format(key, request.form[key]))
                if "insertassociativefor" in key:
                    if key.endswith("_child"):
                        parent_name = key[:-len("_child")]
                        multi_level_associations_parents_to_children[parent_name] = request.form[key]

                    elif not key.endswith("_options") and not key.endswith("_label") and not key.endswith("_field_type"):
                        if key.startswith("dynamic") or key.startswith("static"):
                            single_level_associations.append([key, request.form[key]])
                        else:
                            raw_multi_level_associative_metadata.append([key, request.form[key]])

                    # DEBUGGING
                    else:
                        print("NOT ADDED: {0}".format(key))
                        # END DEBUGGING

                elif key != "chosen_entity" and key != "submit_btn":
                    if request.form[key] != "":
                        in_entity_field_values.append([key, request.form[key]])
            
            multi_level_curr_parent = None
            multi_level_curr_children_list = []
            multi_level_parent_with_children = []

            for item in raw_multi_level_associative_metadata:
                print("MULTILEVEL: {0}, {1}".format(item[0], item[1]))
                if item[0].startswith("multibase_"):
                    if multi_level_curr_parent != None:
                        print("ADDING TO PARENT w/CHILDREN: {0}".format([multi_level_curr_parent, multi_level_curr_children_list]))
                        multi_level_parent_with_children.append([multi_level_curr_parent, multi_level_curr_children_list])
                        multi_level_curr_parent = item
                        multi_level_curr_children_list = []
                    else:
                        multi_level_curr_parent = item
                else:
                    multi_level_curr_children_list.append(item)

            if multi_level_curr_parent != None:
                multi_level_parent_with_children.append([multi_level_curr_parent, multi_level_curr_children_list])
                multi_level_curr_children_list = []
            
            new_id, error = insert_new_base_entity_record_into_db(chosen_entity, in_entity_field_values, single_level_associations, multi_level_parent_with_children)
            if error == None:
                return redirect(url_for('entity_details', entity=chosen_entity, entity_id = new_id))
            else:
                # TODO: do error handling
                error = True

    chosen_entity = entity

    alphanumeric_attr_list, enum_attr_list = get_alphanumeric_and_enum_attr_lists(chosen_entity)

    include_creator_id = False
    fk_set_list = get_fk_set_list(chosen_entity, include_creator_id)

    direct_attr_list, multilinked_attr_list = get_dynamic_associative_attr_lists_for_create(chosen_entity, True)

    # 1. Get all fields directly in the record of that entity
    # 2. Get all foreign fields
    #    a. If DM_ID, DON'T SHOW
    #    b. Else, do drop down thing from search
    # 3. Options for associative records
    #

    return render_template('create_details.html', chosen_entity=entity, alphanumeric_attr_list=alphanumeric_attr_list, enum_attr_list=enum_attr_list, fk_set_list=fk_set_list, direct_attr_list=direct_attr_list, multilinked_attr_list=multilinked_attr_list, logged_in_user_details=logged_in_user_details)


@app.route('/search', methods=['GET', 'POST'])
def search():
    # if logged_in_user == None:
    if logged_in_user_details['username'] == None:
        return redirect('/login')

    if request.method == 'POST':
        chosen_entity = request.form['chosen_entity']
        search_fields_url = "search_fields_template/{0}".format(chosen_entity.lower())

        # DEBUGGING
        print(chosen_entity)
        # END DEBUGGING

        return render_template('search.html', entities=searchable_entities, chosen_entity=chosen_entity, search_fields_link=search_fields_url, logged_in_user_details=logged_in_user_details)
    return render_template('search.html', entities=searchable_entities, chosen_entity=searchable_entities[0], search_fields_link=None, logged_in_user_details=logged_in_user_details)


# removed 'POST' option in test 4/27 , methods=['GET', 'POST']
@app.route('/search_fields_template/<name>')
def search_fields_template(name):
    chosen_entity = name

    include_creator_id = True

    alphanumeric_attr_list, enum_attr_list = get_alphanumeric_and_enum_attr_lists(chosen_entity)

    fk_set_list = get_fk_set_list(chosen_entity, include_creator_id)

    return render_template('search_fields_template.html', chosen_entity=chosen_entity, alphanumeric_attr_list=alphanumeric_attr_list, enum_attr_list=enum_attr_list, fk_set_list=fk_set_list)


@app.route('/search_result', methods=['POST', 'GET'])
def search_result():
    records = []
    chosen_entity = ""

    if request.method == 'POST':
        search_fields = []
        for item in request.form:
            key = item
            value = request.form[item]

            # DEBUGGING
            print("KEY VALUE: '{0}', '{1}'".format(key,value))
            # END DEBUGGING

            if key == "chosen_entity":
                chosen_entity = value.lower()
            elif value != "":
                search_fields.append("{0} = '{1}'".format(key,value))

        condition = ""
        if len(search_fields) > 0:
            condition = "WHERE {0}".format(" AND ".join(search_fields))
        #
        # # DB side TODO: create displays for all searchable entities => FROM statement here
        # search_statement = "SELECT * FROM {0}".format(chosen_entity)
        # if len(search_fields) > 0:
        #     search_statement = "{0} WHERE {1}".format(search_statement, " AND ".join(search_fields))
        #
        # print("SEARCH STATEMENT: '{0}'".format(search_statement))
        # TODO: amend for DB side display view as to what columns get
        # results = execute_cmd_and_get_result(search_statement)
        print("Entity, Search: '{0}', '{1}'".format(chosen_entity, condition))
        results = execute_cmd_and_get_result("CALL get_previews('{0}', '{1}')".format(chosen_entity, condition))
        # columns = execute_cmd_and_get_result("CALL get_all_column_names('{0}')".format(chosen_entity))

        records_and_metadata = get_formatted_previews_and_metadata_list(results)

    return render_template('search_result.html', records_and_metadata=records_and_metadata, logged_in_user_details=logged_in_user_details)


#TODO: stub
@app.route('/entity_details/<entity>/<entity_id>', methods=['GET', 'POST'])
def entity_details(entity, entity_id):
    if logged_in_user_details['username'] == None:
        return redirect('/login')
    
    if request.method == "POST":
        called_key = None
        for key in request.form:
            if key.startswith("updatebtn_"):
                called_key = key[len("updatebtn_"):]
                break
        
        if called_key == None:
            print("NO UPDATE CALLED FOR ENTITY")
        else:
            print("UPDATED VALUE: KEY: {0}, VALUE: {1}".format(called_key, request.form[called_key]))
            condition = "WHERE ID = '{0}'".format(entity_id)
            execute_cmd("CALL update_field_in_table('{0}_details', '{1}', '{2}', '{3}')".format(entity, called_key, request.form[called_key], condition))

    chosen_entity = entity

    alphanumeric_attr_list, enum_attr_list = get_alphanumeric_and_enum_attr_lists_with_values_for_details(chosen_entity, entity_id)

    # TODO: get for associative attributes that already exist in table

    direct_attr_list_values_and_templates, multilinked_attr_list_values_and_templates = get_associative_attr_lists_for_entity_details(chosen_entity, entity_id, True)

    return render_template('entity_details.html', chosen_entity = chosen_entity, alphanumeric_attr_list=alphanumeric_attr_list, enum_attr_list=enum_attr_list, direct_attr_list=direct_attr_list_values_and_templates, multilinked_attr_list=multilinked_attr_list_values_and_templates, logged_in_user_details=logged_in_user_details)


def connect(in_user=None):
    if in_user == None:
        in_user = connection_values['mysql_user']
    db = mysql.connector.connect(
            host=connection_values['mysql_host'],
            user=in_user,
            passwd=connection_values['mysql_password'],
            database=connection_values['mysql_db']
        )

    return db


def player_login(username):
    # TODO: replace with procedure in MySQL that returns all 4 items in 1 call
    global logged_in_user_details
    logged_in_user_details['username'] = username

    # global logged_in_user_nickname
    # logged_in_user_nickname = execute_cmd_and_get_result("SELECT player_nickname FROM player WHERE player_username = '{0}'".format(logged_in_user))[0][0]
    logged_in_user_details['nickname'] = execute_cmd_and_get_result("SELECT player_nickname FROM player WHERE player_username = '{0}'".format(logged_in_user_details['username']))[0][0]

    dm_id_result = execute_cmd_and_get_result("SELECT dm_id FROM dungeonmaster JOIN player USING(player_id) WHERE player_username = '{0}'".format(logged_in_user_details['username']))
    if len(dm_id_result) > 0:
        logged_in_user_details['dm_id'] = dm_id_result[0][0]
    else:
        logged_in_user_details['dm_id'] = None

    logged_in_user_details['player_id'] = execute_cmd_and_get_result("SELECT player_id FROM player WHERE player_username = '{0}'".format(logged_in_user_details['username']))[0][0]
    # global logged_in_user_details
    # logged_in_user_details = {}

    return


def update_player_nickname(nickname):
    global logged_in_user_details
    player_id = logged_in_user_details['player_id']

    successful_update = execute_field_update("player", "player_nickname", nickname, "WHERE player_id = {0}".format(player_id))
    if successful_update:

        updated_nickname = execute_cmd_and_get_result("SELECT player_nickname FROM player WHERE player_id = {0}".format(player_id))[0][0]

        # DEBUGGING
        print("UPDATED NICKNAME: {0}".format(updated_nickname))
        # END DEBUGGING

        logged_in_user_details['nickname'] = updated_nickname


def username_invalid(username):
    return re.search(r'[^a-zA-Z0-9_]', username)


# TODO: add password length max
def password_invalid(password):
    return re.search(r'[^a-zA-Z0-9_]', password)


def get_alphanumeric_and_enum_attr_lists(chosen_entity, include_text_attrs=True):
    attr_datatype_list = execute_cmd_and_get_result("CALL get_non_foreign_key_column_names_and_datatypes('{0}')".format(chosen_entity))

    # List format: [(name, datatype), (name, datatype), ...]
    alphanumeric_attr_list = []

    # List format: [(name, (allowed_val, allowed_val,...)), (name, (allowed_val, allowed_val, ...))]
    enum_attr_list = []

    # Parse through all local attributes received, distinguishing enums from all other types
    for attr_set in attr_datatype_list:
        attr_name = attr_set[0]
        attr_datatype = attr_set[1]

        # If an enum, convert all of the allowed values into a list, and associate list w/attr name
        if "enum" in attr_datatype:
            enum_vals = [enum_val[1:-1] if enum_val[0] == "'" and enum_val[len(enum_val) - 1] == "'" else enum_val for enum_val in attr_datatype.split("enum")[1][1:-1].split(",")]
            enum_vals.insert(0, default_dropdown_str)
            enum_attr_list.append([attr_name, enum_vals])
        else:
            if "text" not in attr_datatype or include_text_attrs:
                attr_datatype_html_pattern, attr_datatype_html_length = convert_mysql_datatype_to_html_datatype(attr_datatype)
                alphanumeric_attr_list.append([attr_name, attr_datatype_html_pattern, attr_datatype_html_length])

    return alphanumeric_attr_list, enum_attr_list


# TODO - combine this with above function once figure out clean way to do so
def get_alphanumeric_and_enum_attr_lists_with_values_for_details(chosen_entity, id_val, include_text_attrs=True):
    # TODO: modify DB end so not need to include "_details" in this call, but auto selects from details panel instead? => ISSUE: lose foreign key info...
    attr_datatype_list = execute_cmd_and_get_result("CALL get_non_foreign_key_column_names_and_datatypes('{0}_details')".format(chosen_entity))

    values_with_readonly_information = execute_cmd_and_get_result("CALL get_direct_entity_details('{0}', '{1}', '{2}')".format(chosen_entity, id_val, logged_in_user_details['player_id']))
    
    # DEBUGGING
    print("attr_datatype_list w/READONLY INFO: {0}".format(attr_datatype_list))
    print("VALUES w/READONLY INFO: {0}".format(values_with_readonly_information))
    # END DEBUGGING

    # TODO: check this
    if len(values_with_readonly_information) <= 1:
        # DEBUGGING
        print("UH - OH: TERMINATED VALUE COLLECTION PREMATURELY")
        # END DEBUGGING
        # TODO: maybe change the returns back to Nones
        return [], []
    
    readonly_info = values_with_readonly_information.pop(0)
    all_record_values = values_with_readonly_information

    # 5/7 TODO: account for possibility of multiple sets of values inside of values, not just vals for only one record!

    # readonly_info, values = values_with_readonly_information

    # For alphanum and enum lists, each full list set at upper most level correspond to a single record
    # List format: [ [(name, datatype, readonly, value), (name, datatype, readonly, value), ...], [(name, datatype, readonly, value), (name, datatype, readonly, value), ...], ... ]
    all_records_alphanumeric_attr_list = []

    # List format: [ [(name, (allowed_val, allowed_val,...), readonly, value), (name, (allowed_val, allowed_val, ...), readonly, value)], [(name, (allowed_val, allowed_val,...), readonly, value), (name, (allowed_val, allowed_val, ...), readonly, value)], ...]
    all_records_enum_attr_list = []

    # Parse through all local attributes received, distinguishing enums from all other types
    # do range truncation to be safe, but shouldn't be possible to get mismatch
    for curr_record_values in all_record_values:
        alphanumeric_attr_list = []
        enum_attr_list = []

        for i in range(0, min(min(len(attr_datatype_list), len(curr_record_values)), len(readonly_info))):
        # for attr_set in attr_datatype_list:
            attr_name = attr_datatype_list[i][0]
            attr_datatype = attr_datatype_list[i][1]
            attr_readonly = readonly_info[i]
            attr_value = curr_record_values[i]

            # If an enum, convert all of the allowed values into a list, and associate list w/attr name
            if "enum" in attr_datatype:
                enum_vals = [enum_val[1:-1] if enum_val[0] == "'" and enum_val[len(enum_val) - 1] == "'" else enum_val for enum_val in attr_datatype.split("enum")[1][1:-1].split(",")]
                # enum_vals.insert(0, default_dropdown_str)
                if attr_readonly.lower() == "no":
                    attr_readonly = "disabled"
                enum_attr_list.append([attr_name, enum_vals, attr_readonly, attr_value])
            else:
                if "text" not in attr_datatype or include_text_attrs:
                    attr_datatype_html_pattern, attr_datatype_html_length = convert_mysql_datatype_to_html_datatype(attr_datatype)
                    if attr_readonly.lower() == "no":
                        attr_readonly = "readonly"
                    alphanumeric_attr_list.append([attr_name, attr_datatype_html_pattern, attr_datatype_html_length, attr_readonly, attr_value])
        
        all_records_alphanumeric_attr_list.append(alphanumeric_attr_list)
        all_records_enum_attr_list.append(enum_attr_list)

    # DEBUGGING
    print("ALPHANUM ATTR LIST: {0}".format(all_records_alphanumeric_attr_list))
    print("ENUM ATTR LIST: {0}".format(all_records_enum_attr_list))
    # END DEBUGGING

    return all_records_alphanumeric_attr_list, all_records_enum_attr_list


# def get_fk_set_list(chosen_entity, include_creator):
#     foreign_key_names_and_tables = execute_cmd_and_get_result("CALL get_foreign_key_column_names_and_referenced_table_names('{0}')".format(chosen_entity))
    
#     # List format: [(foreign_table, fk_column_in_foreign_table, (fk_display_name, how display name was generated, fk value, fk col name in foreign table))]
#     fk_set_list = []

#     # For each foreign table that the base table references (given as pair: foreign key col name in base table, referenced table name)
#     for pair in foreign_key_names_and_tables:
#         local_fk_name = pair[0]
#         referenced_table = pair[1]

#         # TODO 5/3: check that addition at end of line didn't break functionality
#         is_creator_reference = (local_fk_name.lower() == "player_id" and chosen_entity == "character") or (local_fk_name.lower() == "dm_id") or (local_fk_name.lower() == 'monsterparty_id' and chosen_entity == 'monsterencounter')

#         if include_creator or not is_creator_reference:
#             # Get the display and identification information for all records in that table
#             referenced_table_record_names_and_metadata = get_displayname_displaycolname_fk_fkcolname_for_all_records_in_table(referenced_table)
        
#             # If there were records in the table
#             if len(referenced_table_record_names_and_metadata) > 0:

#                 # Save the name of the fk column for use in searching later
#                 foreign_key_col_name = referenced_table_record_names_and_metadata[0][3]

#                 # Insert a dummy entry, to have a "no selection" option for dropdowns
#                 referenced_table_record_names_and_metadata.insert(0, [default_dropdown_str, "", "", ""])
            
#                 # Add a new entry into the traversable set of all foreign key value dropdowns: table name, fk column name, records with embedded fk value options
#                 fk_set_list.append([referenced_table, foreign_key_col_name, referenced_table_record_names_and_metadata])
            
#                 # DEBUGGING
#                 # print([referenced_table, foreign_key_col_name, referenced_table_record_names_and_metadata])
#                 # END DEBUGGING

#     return fk_set_list


# TODO: possibly add fk_condition to this function and db-side function, to allow limiting of fk vals returned
def get_fk_set_list(base_entity, include_creator, associative_entity=None, add_defaults=True, add_creator_condition=False):
    # DEBUGGING
    print("\nGET FK SETS: params - base entity: '{0}', include_creator: '{1}', associative_entity: '{2}', add_defaults: '{3}', associative entity != None: {4}".format(base_entity, include_creator, associative_entity, add_defaults, associative_entity != None))
    # END DEBUGGING

    entity_to_call_on = None
    if associative_entity != None:
        entity_to_call_on = associative_entity
    else:
        entity_to_call_on = base_entity

    foreign_key_names_and_tables = execute_cmd_and_get_result("CALL get_foreign_key_column_names_and_referenced_table_names('{0}')".format(entity_to_call_on))
    
    # List format: [(foreign_table, fk_column_in_foreign_table, (fk_display_name, how display name was generated, fk value, fk col name in foreign table))]
    fk_set_list = []

    # For each foreign table that the base table references (given as pair: foreign key col name in base table, referenced table name)
    for pair in foreign_key_names_and_tables:
        local_fk_name = pair[0]
        referenced_table = pair[1]

        # TODO 5/3: check that addition at end of line didn't break functionality
        is_creator_reference = False
        if associative_entity != None:
            is_creator_reference = (referenced_table == base_entity) or (local_fk_name.lower() == "player_id" and base_entity == "character") or (local_fk_name.lower() == "dm_id") or (local_fk_name.lower() == 'monsterparty_id' and base_entity == 'monsterencounter')
        else:
            is_creator_reference = (local_fk_name.lower() == "player_id" and base_entity == "character") or (local_fk_name.lower() == "dm_id") or (local_fk_name.lower() == 'monsterparty_id' and base_entity == 'monsterencounter')

        if include_creator or not is_creator_reference:
            # Get the display and identification information for all records in that table
            referenced_table_record_names_and_metadata = None

            if entity_to_call_on == "partymember" and referenced_table == "campaign":
                referenced_table_record_names_and_metadata = execute_cmd_and_get_result("CALL get_display_vals_for_fk_records_with_member_condition('{0}')".format(logged_in_user_details['player_id']))
            elif add_creator_condition:
                referenced_table_record_names_and_metadata = get_displayname_displaycolname_fk_fkcolname_for_all_records_in_table_created_by_current_user(referenced_table)
            else:
                referenced_table_record_names_and_metadata = get_displayname_displaycolname_fk_fkcolname_for_all_records_in_table(referenced_table)
        
            # DEBUGGING
            print("FK SET LIST: TABLE NAMES AND METADATA - \n ----------------- \n {0} \n ------------------ \n".format(referenced_table_record_names_and_metadata))
            # END DEBUGGING
        
            # If there were records in the table
            if len(referenced_table_record_names_and_metadata) > 0:

                # Save the name of the fk column for use in searching later
                foreign_key_col_name = referenced_table_record_names_and_metadata[0][3]

                # Insert a dummy entry, to have a "no selection" option for dropdowns
                if add_defaults:
                    referenced_table_record_names_and_metadata.insert(0, [default_dropdown_str, "", "", ""])
            
                # Add a new entry into the traversable set of all foreign key value dropdowns: table name, fk column name, records with embedded fk value options
                fk_set_list.append([referenced_table, foreign_key_col_name, referenced_table_record_names_and_metadata])
            
                # DEBUGGING
                # print([referenced_table, foreign_key_col_name, referenced_table_record_names_and_metadata])
                # END DEBUGGING

    return fk_set_list


# This function is a complete nightmare
def get_dynamic_associative_attr_lists_for_create(entity, allow_recursion):
    
    # TODO 5/1: determine which associative tables to include, and add fields for those
    #           a. Need to distinguish between those w/set number, and those that are dynamic
    #           b. AND for those that are dynamic, need way for users to increase # of fields
    associated_table_names_and_fkcol_names = execute_cmd_and_get_result("CALL get_associated_table_and_fkcol_names_for_create('{0}')".format(entity))
    # [(dynamic/fixed, table to insert into, linked_table_name, [(displayvals), (displayvals), ...])]
    dynamic_attr_list = []

    # [[table to insert into, linked_table_name, [(displayvals), (displayvals), ...]], [table to insert into for other table to insert into, linked_table_name, [(displayvals), (displayvals), ...]],...)
    multilinked_dynamic_attr_list = []

    for trio in associated_table_names_and_fkcol_names:
        linking_table = trio[0]
        associated_table = trio[1]
        fk_in_associated_table = trio[2]

        # get display names for curr_table
        # decide if is dynamic/not based on some condition
        # if static, hard get all poss values and set as text fields/ w/e
        # if dynamic, save info

        # only character class delays some of its returned associated creations
        if entity == 'character' or entity == 'monster':
            if associated_table == "ability" or associated_table == "campaign":
                associative_type = ""
                add_defaults = False

                if associated_table == "ability":
                    associative_type = "static-list"
                else:
                    associative_type = "static-dropdown"
                    add_defaults = True
                # static => collect all values and make into input text fields
                # 1. get all unique instances w/display name
                # 2. get datatype
                # 3. append: (associative_table_name, associated_table_name, [(associated_table_fk_name, associated_fk_val, associated_display_name)])
                attr_vals = get_fk_set_list(entity, False, linking_table, add_defaults)
                attr_vals_and_table_data = [associative_type, linking_table, attr_vals]
                dynamic_attr_list.append(attr_vals_and_table_data)

            elif associated_table == "language":
                attr_vals = get_fk_set_list(entity, False, linking_table, False)
                attr_vals_and_table_data = ["dynamic", linking_table, attr_vals]
                dynamic_attr_list.append(attr_vals_and_table_data)
            
            # 5/7 TODO: add for partymember

        elif entity == 'monsterparty':
            # ([monsterencounter, monster, (monster vals)], [lootitem, item, (item vals)])
            if associated_table == 'monsterencounter':
                print("\n\nAS INTENDED: link = {0}".format(linking_table))
                direct_fk_set_list = get_fk_set_list(entity, False, linking_table, False)

                # direct_attr_vals_and_table_data = ["dynamic", linking_table, direct_fk_set_list]
                
                if allow_recursion:
                    indirect_dynamic_attrs, indirect_multi_attrs = get_dynamic_associative_attr_lists_for_create(associated_table, False)
                    # big yikes

                    # indirect_attr_vals_and_table_data = indirect_dynamic_attrs

                    # multilinked_dynamic_attr_list.append([direct_attr_vals_and_table_data, indirect_attr_vals_and_table_data])
                    direct_fk_set_list.append(indirect_dynamic_attrs)
                    multilinked_dynamic_attr_list.append(["dynamic", linking_table, direct_fk_set_list])
                else:
                    # this probably doesn't work at all
                    # DEBUGGING
                    print("THIS SHOULDN'T HAPPEN AND IF IT DOES, WE HAVE A PROBLEM")
                    # END DEBUGGING
                    dynamic_attr_list.extend(["dynamic", linking_table, direct_fk_set_list])
        else:
            # aside from monsters with ability scores, no other entity has a static attr list
            attr_vals = get_fk_set_list(entity, False, linking_table, False)
            attr_vals_and_table_data = ["dynamic", linking_table, attr_vals]
            dynamic_attr_list.append(attr_vals_and_table_data)

    # DEBUGGING
    print("\n CALLER: {2} >> DYNAMIC: {0} - MULTILINKED: {1}".format(len(dynamic_attr_list), len(multilinked_dynamic_attr_list), entity))
    print("\n DYNAMIC: {0}".format(dynamic_attr_list))
    print("\n MULTILINKED: {0}".format(multilinked_dynamic_attr_list))
    # if len(multilinked_dynamic_attr_list) > 0:
    #     print("MULTILINKED[0][1]: {0}".format(multilinked_dynamic_attr_list[0][1]))
    # for i in range(0, min(10, len(dynamic_attr_list))):
    #     # print("DYNAMIC: '{0}'".format(dynamic_attr_list[i]))
    #     print("\nHAVE DYNAMIC")
    #     if i < len(multilinked_dynamic_attr_list):
    #         # print("MULTILINKED: '{0}'".format(multilinked_dynamic_attr_list[i]))
    #         print("\nHAVE MULTILINKED")
    # END DEBUGGING

    return dynamic_attr_list, multilinked_dynamic_attr_list


# TODO: figure out clean way to combine this w/function above
def get_associative_attr_lists_for_entity_details(entity, entity_id, allow_recursion):

    associated_table_names_and_fkcol_names = execute_cmd_and_get_result("CALL get_associated_table_and_fkcol_names_for_create('{0}')".format(entity))
    # [(dynamic/fixed, table to insert into, linked_table_name, [(displayvals), (displayvals), ...])]
    dynamic_attr_list = []

    # [[table to insert into, linked_table_name, [(displayvals), (displayvals), ...]], [table to insert into for other table to insert into, linked_table_name, [(displayvals), (displayvals), ...]],...)
    multilinked_dynamic_attr_list = []

    for trio in associated_table_names_and_fkcol_names:
        linking_table = trio[0]
        associated_table = trio[1]
        fk_in_associated_table = trio[2]

        preexisting_vals_calling_entity = linking_table
        if linking_table == "partymember":
            if entity == "campaign":
                preexisting_vals_calling_entity = "player_partymember"
            else:
                preexisting_vals_calling_entity = "character_partymember"

        preexisting_alphanumeric_metadata_and_values, preexisting_enum_metadata_and_values = get_alphanumeric_and_enum_attr_lists_with_values_for_details(preexisting_vals_calling_entity, entity_id)

        # only character class delays some of its returned associated creations
        if entity == 'character' or entity == 'monster':
            associative_relationship_type = "dynamic"

            if associated_table == "ability":
                dynamic_attr_list.append([preexisting_alphanumeric_metadata_and_values, preexisting_enum_metadata_and_values, []])
            # 5/7 TODO: if associated_table == "partymember" AND there does not exist preexisting value, then do static-dropdown
            elif associated_table == "campaign":
                # DEBUGGING
                print("GET ASSOCIATIVES FOR DETAILS: PREEXISTING: \n alphanum: \n {0} \n enum: \n {1}".format(preexisting_alphanumeric_metadata_and_values, preexisting_enum_metadata_and_values))
                # END DEBUGGING
                # 
                if len(preexisting_alphanumeric_metadata_and_values) == 0:
                    attr_vals_for_dynamic_additions = get_fk_set_list(entity, False, linking_table, True)
                    attr_vals_and_metadata_for_dynamic_additions = ["static-dropdown", linking_table, attr_vals_for_dynamic_additions]
                    dynamic_attr_list.append([preexisting_alphanumeric_metadata_and_values, preexisting_enum_metadata_and_values, attr_vals_and_metadata_for_dynamic_additions])
                else:
                    dynamic_attr_list.append([preexisting_alphanumeric_metadata_and_values, preexisting_enum_metadata_and_values, []])
            else:
            # # If ability, need to collect existing values ONLY, not template;
            # # for any other table, collect both existing values and template
            # if associated_table == "ability":
            #     associative_relationship_type = "static"
            # else:
            #     associative_relationship_type = "dynamic"
            #     # static => collect all values and make into input text fields
            #     # 1. get all unique instances w/display name
            #     # 2. get datatype
            #     # 3. append: (associative_table_name, associated_table_name, [(associated_table_fk_name, associated_fk_val, associated_display_name)])
                attr_vals_for_dynamic_additions = get_fk_set_list(entity, False, linking_table, False)
                attr_vals_and_metadata_for_dynamic_additions = [associative_relationship_type, linking_table, attr_vals_for_dynamic_additions]
                dynamic_attr_list.append([preexisting_alphanumeric_metadata_and_values, preexisting_enum_metadata_and_values, attr_vals_and_metadata_for_dynamic_additions])

            # elif associated_table == "language":
            #     attr_vals = get_fk_set_list(entity, False, linking_table, False)
            #     attr_vals_and_table_data = ["dynamic", linking_table, attr_vals]
            #     dynamic_attr_list.append(attr_vals_and_table_data)

        elif entity == 'monsterparty':
            # ([monsterencounter, monster, (monster vals)], [lootitem, item, (item vals)])
            if associated_table == 'monsterencounter':
                print("\n\nAS INTENDED: link = {0}".format(linking_table))
                direct_fk_set_list = get_fk_set_list(entity, False, linking_table, False)

                # direct_attr_vals_and_table_data = ["dynamic", linking_table, direct_fk_set_list]
                
                if allow_recursion:
                    indirect_dynamic_attrs, indirect_multi_attrs = get_associative_attr_lists_for_entity_details(associated_table, entity_id, False)
                    # big yikes

                    # indirect_attr_vals_and_table_data = indirect_dynamic_attrs

                    # multilinked_dynamic_attr_list.append([direct_attr_vals_and_table_data, indirect_attr_vals_and_table_data])
                    direct_fk_set_list.append(indirect_dynamic_attrs)
                    multilinked_attr_vals_and_metadata_for_dynamic_additions = ["dynamic", linking_table, direct_fk_set_list]
                    multilinked_dynamic_attr_list.append([preexisting_alphanumeric_metadata_and_values, preexisting_enum_metadata_and_values, multilinked_attr_vals_and_metadata_for_dynamic_additions])
                else:
                    # this probably doesn't work at all
                    # DEBUGGING
                    print("THIS SHOULDN'T HAPPEN AND IF IT DOES, WE HAVE A PROBLEM")
                    # END DEBUGGING
                    attr_vals_and_metadata_for_dynamic_additions = ["dynamic", linking_table, direct_fk_set_list]
                    dynamic_attr_list.extend([preexisting_enum_metadata_and_values, preexisting_enum_metadata_and_values, attr_vals_and_metadata_for_dynamic_additions])
        else:
            # aside from monsters with ability scores, no other entity has a static attr list
            attr_vals_for_dynamic_additions = get_fk_set_list(entity, False, linking_table, False)
            attr_vals_and_metadata_for_dynamic_additions = ["dynamic", linking_table, attr_vals_for_dynamic_additions]
            dynamic_attr_list.append([preexisting_alphanumeric_metadata_and_values, preexisting_enum_metadata_and_values, attr_vals_and_metadata_for_dynamic_additions])

    # DEBUGGING
    print("\n CALLER: {2} >> DYNAMIC: {0} - MULTILINKED: {1}".format(len(dynamic_attr_list), len(multilinked_dynamic_attr_list), entity))
    # if len(multilinked_dynamic_attr_list) > 0:
    #     print("MULTILINKED[0][1]: {0}".format(multilinked_dynamic_attr_list[0][1]))
    # for i in range(0, min(10, len(dynamic_attr_list))):
    #     # print("DYNAMIC: '{0}'".format(dynamic_attr_list[i]))
    #     print("\nHAVE DYNAMIC")
    #     if i < len(multilinked_dynamic_attr_list):
    #         # print("MULTILINKED: '{0}'".format(multilinked_dynamic_attr_list[i]))
    #         print("\nHAVE MULTILINKED")
    # END DEBUGGING

    return dynamic_attr_list, multilinked_dynamic_attr_list


def upgrade_player_to_dm():
    global logged_in_user_details
    if logged_in_user_details['dm_id'] == None:
        execute_cmd("INSERT INTO dungeonmaster(player_id) VALUES({0})".format(logged_in_user_details['player_id']))


def insert_new_base_entity_record_into_db(chosen_entity, in_entity_field_values, single_level_associations, multi_level_parent_with_children):
    try:
        global logged_in_user_details

        # DEBUGGING
        print("CHOSEN ENTITY: {0}".format(chosen_entity))
        print("DIRECT VALUES: {0}".format(in_entity_field_values))
        print("SINGLE LEVEL ASSOCIATIONS: {0}".format(single_level_associations))
        print("MULTILEVEL ASSOCIATIONS: {0}".format(multi_level_parent_with_children))
        
        # insert for base entity
        db = connect()
        cursor = db.cursor()

        curr_col_list_str = ",".join([col_name_and_val[0] for col_name_and_val in in_entity_field_values])
        curr_val_list_str = ",".join(["'{0}'".format(col_name_and_val[1]) for col_name_and_val in in_entity_field_values])

        if chosen_entity == "character":
            curr_col_list_str += ",player_id"
            curr_val_list_str += ",'{0}'".format(logged_in_user_details['player_id'])
        else:
            curr_col_list_str += ",dm_id"
            curr_val_list_str += ",'{0}'".format(logged_in_user_details['dm_id'])

        # base_entity = chosen_entity
        # if chosen_entity == "character" or chosen_entity == "language":
        #     base_entity = "`{0}`".format(base_entity)

        # curr_cmd = "INSERT INTO {0}({1}) VALUES({2})".format(base_entity, curr_col_list_str, curr_val_list_str)

        curr_cmd = "CALL insert_record('{0}', '{1}', '{2}')".format(chosen_entity, curr_col_list_str, curr_val_list_str)

        print("DIRECT INSERT CMD: {0}".format(curr_cmd))
        # execute_partial_transaction_cmd(curr_cmd, cursor)
        # curr_cmd = "CALL get_most_recent_pk_val_and_pk_colname({0})".format(chosen_entity)
        # curr_base_pk_val, curr_base_pk_name = execute_partial_transaction_cmd_and_get_result(curr_cmd, cursor)[0]
        # saved_base_entity = chosen_entity
        execute_partial_transaction_cmd(curr_cmd, cursor)

        saved_base_pk_val, saved_base_pk_name = execute_partial_transaction_cmd_and_get_result("CALL get_most_recent_pk_val_and_pk_colname('{0}')".format(chosen_entity), cursor)[0][0]
        
        # DEBUGGING
        print("INSERTED PK AND VAL: {0}, {1}".format(saved_base_pk_val, saved_base_pk_name))

        # print("LAST_INSERT_ID: {0}".format(execute_partial_transaction_cmd_and_get_result("SELECT LAST_INSERT_ID()")))
        # END DEBUGGING

        prev_possibly_repeatable_dynamic_inserts = []

        for single_level_association in single_level_associations:
            if single_level_association[0].startswith("static"):
                parsed_list = None
                if single_level_association[0].startswith("static-dropdown"):
                    parsed_list = get_insert_entity_and_col_name_and_col_value_from_embedded_associative_str(single_level_association[1])
                else:
                    parsed_list = get_insert_entity_and_col_name_and_col_value_from_embedded_associative_str(single_level_association[0])
                print("SINGLE - STATIC: {0}".format(parsed_list))

                curr_entity = parsed_list[0]

                if curr_entity == "partymember" and chosen_entity == "character":
                    # 5/7 TODO: CHECK THIS! \/
                    curr_cmd = "CALL conditional_partymember_record_insert_for_character('{0}', '{1}', '{2}')".format(saved_base_pk_val, logged_in_user_details['player_id'], parsed_list[2])
                    execute_partial_transaction_cmd(curr_cmd, cursor)
                else:
                    curr_col_list_str = "{0},{1}".format(saved_base_pk_name, parsed_list[1])
                    curr_val_list_str = "'{0}','{1}','{2}'".format(saved_base_pk_val, parsed_list[2], single_level_association[1])

                    curr_cmd = "CALL insert_record('{0}', '{1}', '{2}')".format(curr_entity, curr_col_list_str, curr_val_list_str)
                    print("STATIC INSERT CMD: {0}".format(curr_cmd))

                    execute_partial_transaction_cmd(curr_cmd, cursor)
            else:
                parsed_list = get_insert_entity_and_col_name_from_embedded_associative_str(single_level_association[0])
                print("SINGLE - DYNAMIC: {0}".format(parsed_list))

                curr_entity = parsed_list[0]
                curr_col_list_str = "{0},{1}".format(saved_base_pk_name, parsed_list[1])
                curr_val_list_str = "'{0}','{1}'".format(saved_base_pk_val, single_level_association[1])
                curr_cmd = "CALL insert_record('{0}', '{1}', '{2}')".format(curr_entity, curr_col_list_str, curr_val_list_str)
                print("DYNAMIC INSERT CMD: {0}".format(curr_cmd))

                if curr_cmd not in prev_possibly_repeatable_dynamic_inserts:
                    prev_possibly_repeatable_dynamic_inserts.append(curr_cmd)
                    print("UNREPEATED DYNAMIC CMD")

                    execute_partial_transaction_cmd(curr_cmd, cursor)

        for multi_level_association in multi_level_parent_with_children:
            curr_base_pk_name = saved_base_pk_name
            curr_base_pk_val = saved_base_pk_val

            parent_name_and_value = multi_level_association[0]
            children_list = multi_level_association[1]

            associative_parent_parsed_list = get_insert_entity_and_col_name_from_embedded_associative_str(parent_name_and_value[0])
            print("MULTI - PARENT: {0}".format(associative_parent_parsed_list))

            curr_entity = associative_parent_parsed_list[0]
            curr_col_list_str = "{0},{1}".format(curr_base_pk_name, associative_parent_parsed_list[1])
            curr_val_list_str = "'{0}','{1}'".format(curr_base_pk_val, parent_name_and_value[1])

            curr_cmd = "CALL insert_record('{0}', '{1}', '{2}')".format(curr_entity, curr_col_list_str, curr_val_list_str)
            print("MULTI - PARENT INSERT CMD: {0}".format(curr_cmd))

            execute_partial_transaction_cmd(curr_cmd, cursor)

            curr_base_pk_val, curr_base_pk_name = execute_partial_transaction_cmd_and_get_result("CALL get_most_recent_pk_val_and_pk_colname('{0}')".format(curr_entity), cursor)[0][0]

            for child_name_and_value in children_list:
                associative_child_parsed_list = get_insert_entity_and_col_name_from_embedded_associative_str(child_name_and_value[0])
                print("MULTI - CHILD: {0}".format(associative_child_parsed_list))

                curr_entity = associative_child_parsed_list[0]
                curr_col_list_str = "{0},{1}".format(curr_base_pk_name, associative_child_parsed_list[1])
                curr_val_list_str = "'{0}','{1}'".format(curr_base_pk_val, child_name_and_value[1])

                curr_cmd = "CALL insert_record('{0}', '{1}', '{2}')".format(curr_entity, curr_col_list_str, curr_val_list_str)

                print("MULTI - CHILD INSERT CMD: {0}".format(curr_cmd))

                execute_partial_transaction_cmd(curr_cmd, cursor)

        # END DEBUGGING
        #
        # db = connect()
        # cursor = db.cursor()
        # # start transaction
        # # insert into chosen_entity values in in_entity_field_values
        # error = execute_partial_transaction_cmd("")
        # # get id of newly created entity in form: "pk_name=value"
        # # for each single level association:
        # #   insert into associated table: chosen entity's pk_name=value, distant associated entity's pk_name=value, any other vals (ex. abilityscore)
        # # for each multi level association:
        # #   1. insert parent
        # #   2. get parent generated id in form:"pk_name=value"
        # #   3. For each child:
        # #       Insert into distant associated table: parent's pk_name=value, 
        # # end transaction
        # # commit transaction
        # db.commit()
        # cursor.close()
        # db.close()
        db.commit()
        cursor.close()
        db.close()
        return saved_base_pk_val, None
    except Exception as e:
        print("INSERT RECORD EXCEPTION - {0}".format(e))
        cursor.close()
        db.close()
        raise e
        # rollback?
        return None, e


# TODO: replace every other instance of execute to get fetchall() with this
def execute_cmd_and_get_result(cursor_cmd, multiple_args=True):
    result = None

    db = connect()
    cursor = db.cursor()

    # Handle stored procedure call
    if cursor_cmd.startswith("CALL "):
        procedure_name_and_args = cursor_cmd[5:]
        procedure_name, procedure_args_block = procedure_name_and_args.split("(", 1)

        unformatted_procedure_args = []
        if multiple_args:
            unformatted_procedure_args = procedure_args_block[:-1].split(", ")
        else:
            unformatted_procedure_args.append(procedure_args_block[:-1])

        procedure_args = [member[1:-1] if member[0] == "'" and member[len(member) - 1] == "'" else member for member in unformatted_procedure_args]
        
        # DEBUGGING
        print("procedure_name: {0} - procedure_args: {1}".format(procedure_name, procedure_args))
        # END DEBUGGING

        cursor.callproc(procedure_name, procedure_args)
        result = []
        for stored_result in cursor.stored_results():
            curr_result_lists = stored_result.fetchall()
            for result_list in curr_result_lists:
                result.append(result_list)
    else:
        cursor.execute(cursor_cmd)
        result = cursor.fetchall()

    db.commit()
    cursor.close()
    db.close()

    return result


def execute_cmd(cursor_cmd, multiple_args=True):
    db = connect()
    cursor = db.cursor()

    # Handle stored procedure call
    if cursor_cmd.startswith("CALL "):
        procedure_name_and_args = cursor_cmd[5:]
        procedure_name, procedure_args_block = procedure_name_and_args.split("(", 1)

        unformatted_procedure_args = []
        if multiple_args:
            unformatted_procedure_args = procedure_args_block[:-1].split(", ")
        else:
            unformatted_procedure_args.append(procedure_args_block[:-1])

        procedure_args = [member[1:-1] if member[0] == "'" and member[len(member) - 1] == "'" else member for member in unformatted_procedure_args]
        
        # DEBUGGING
        print("procedure_name: {0} - procedure_args: {1}".format(procedure_name, procedure_args))
        # END DEBUGGING

        cursor.callproc(procedure_name, procedure_args)
    else:
        cursor.execute(cursor_cmd)

    db.commit()
    cursor.close()
    db.close()


def execute_partial_transaction_cmd_and_get_result(cursor_cmd, cursor, multiple_args=True):
    # try:
    #     result = None
        # Handle stored procedure call
    if cursor_cmd.startswith("CALL "):
        procedure_name_and_args = cursor_cmd[5:]
        procedure_name, procedure_args_block = procedure_name_and_args.split("(", 1)

        unformatted_procedure_args = []
        if multiple_args:
            unformatted_procedure_args = procedure_args_block[:-1].split(", ")
        else:
            unformatted_procedure_args.append(procedure_args_block[:-1])

        procedure_args = [member[1:-1] if member[0] == "'" and member[len(member) - 1] == "'" else member for member in unformatted_procedure_args]
        
        # DEBUGGING
        print("procedure_name: {0} - procedure_args: {1}".format(procedure_name, procedure_args))
        # END DEBUGGING

        cursor.callproc(procedure_name, procedure_args)
        result = []
        for stored_result in cursor.stored_results():
            curr_result_lists = stored_result.fetchall()
            for result_list in curr_result_lists:
                result.append(result_list)

        return result, None
    else:
        cursor.execute(cursor_cmd)
        result = cursor.fetchall()
    # except Exception as e:
    #     return None, e


def execute_partial_transaction_cmd(cursor_cmd, cursor, multiple_args=True):
    # try:
        # Handle stored procedure call
    # Handle stored procedure call
    if cursor_cmd.startswith("CALL "):
        procedure_name_and_args = cursor_cmd[5:]
        procedure_name, procedure_args_block = procedure_name_and_args.split("(", 1)

        unformatted_procedure_args = []
        if multiple_args:
            unformatted_procedure_args = procedure_args_block[:-1].split(", ")
        else:
            unformatted_procedure_args.append(procedure_args_block[:-1])

        procedure_args = [member[1:-1] if member[0] == "'" and member[len(member) - 1] == "'" else member for member in unformatted_procedure_args]
        
        # DEBUGGING
        print("procedure_name: {0} - procedure_args: {1}".format(procedure_name, procedure_args))
        # END DEBUGGING

        cursor.callproc(procedure_name, procedure_args)
    else:
        cursor.execute(cursor_cmd)

    return None

    #except Exception as e:
    #    return e


def execute_field_update(entity, field, new_value, condition):
    try:
        # DEBUGGING
        print("FIELD UPDATE: CALL update_field_in_table('{0}', '{1}', '{2}', '{3}')".format(entity, field, new_value, condition))
        # END DEBUGGING
        execute_cmd("CALL update_field_in_table('{0}', '{1}', '{2}', '{3}')".format(entity, field, new_value, condition))
        return True

    except Exception as e:
         print("Error in field update: {0}".format(e))
         return False


def get_display_name(entity):
    try:
        result = execute_cmd_and_get_result("SELECT get_display_column_name('{0}')".format(entity))
        return result[0][0]
    except:
        return ""


def get_display_and_column_names_select_statement_as_str(entity):
    try:
        result = execute_cmd_and_get_result("SELECT get_display_and_col_names_select_statement('{0}')".format(entity))
        return result[0][0]
    except:
        return ""


def get_displayname_displaycolname_fk_fkcolname_for_all_records_in_table(entity):
    try:
        results = execute_cmd_and_get_result("CALL get_displayname_displaycolname_fkvalue_fkcolname('{0}')".format(entity))
        return results
    except:
        return []


def get_displayname_displaycolname_fk_fkcolname_for_all_records_in_table_created_by_current_user(entity):
    try:
        global logged_in_user_details
        results = execute_cmd_and_get_result("CALL get_displayname_displaycolname_fkvalue_fkcolname_with_condition('{0}', '{1}')".format(entity, logged_in_user_details['player_id']))
        return results
    except:
        return []


# Should only ever be used to for non-enums
def convert_mysql_datatype_to_html_datatype(datatype):
    datatype_text_type = ""
    datatype_length = ""

    alphanumeric = "[a-zA-Z0-9_ ]+" 
    numeric = "[0-9]+"

    datatype = datatype.lower()

    if "enum" in datatype:
        datatype_text_type = alphanumeric
        datatype_length = 255

    elif "text" in datatype:
        datatype_text_type = alphanumeric
        datatype_length = 2048

    elif "varchar" in datatype:
        datatype_text_type = alphanumeric
        datatype_length = datatype.split("(")[1][:-1]

    elif "int" in datatype:
        datatype_text_type = numeric
        datatype_length = datatype.split("(")[1][:-1]

    return datatype_text_type, datatype_length


def get_formatted_previews_and_metadata_list(unformatted_records):
    # unformatted_records, even if no search results, will ALWAYS have
    # at least one entry

    # DEBUGGING
    print("UNFORMATTED: '{0}'".format(unformatted_records))
    # END DEBUGGING
    if len(unformatted_records) <= 1:
        return None

    formatted_records = []
    column_names_list = unformatted_records.pop(0)
    print("Cols: {0}".format(column_names_list))

    num_cols = len(column_names_list)
    for record in unformatted_records:
        curr_record_column_value_pairs = []
        curr_record_generic_identifier_pair = []
        curr_record_identifier_pair = []
        # curr_record_headliner_col_val_pair = []
        curr_record_table_name = ""

        end_index = min(len(record), num_cols)
        for i in range(0, min(1, end_index)):
            curr_record_identifier_metadata_pair = [column_names_list[i], record[i]]
            # DEBUGGING
            print("identifier_pair: {0}".format(curr_record_identifier_metadata_pair))
            # END DEBUGGING

        for i in range(1, min(2, end_index)):
            curr_record_table_name = record[i]
            # DEBUGGING
            print("table_name: {0}".format(curr_record_table_name))
            # END DEBUGGING

        for i in range(2, min(3, end_index)):
            curr_record_identifier_pair = [column_names_list[i], record[i]]
            # DEBUGGING
            print("col_val_pair: {0}".format(curr_record_identifier_pair))
            # END DEBUGGING

        for i in range(3, end_index):
            curr_record_column_value_pairs.append([column_names_list[i], record[i]])
        
        formatted_records.append([curr_record_table_name, curr_record_identifier_metadata_pair, curr_record_identifier_pair, curr_record_column_value_pairs])
    
    if len(formatted_records) == 0:
        formatted_records = None

    return formatted_records


def get_insert_entity_and_col_name_from_embedded_associative_str(embedded_str):
    embedded_str = embedded_str.split("_", 1)[1][:-len("_#")]
    return embedded_str.split("_insertassociativefor_")


def get_insert_entity_and_col_name_and_col_value_from_embedded_associative_str(embedded_str):
    embedded_str = embedded_str.split("_", 1)[1]
    embedded_components = embedded_str.split("_insertassociativefor_")
    embedded_associative_table = embedded_components[0]
    embedded_pk_name_and_val = embedded_components[1].split("=")
    return [embedded_associative_table, embedded_pk_name_and_val[0], embedded_pk_name_and_val[1]]


# TODO: DELETE
@app.route('/players', methods=['GET', 'POST'])
def players():
    if request.method == "POST":
        for key in request.form:
            print("{0}, {1}".format(key, request.form[key]))
    return render_template('players.html')


# TODO: DELETE
@app.route('/dynamic_fields', methods=['GET', 'POST'])
def dynamic_fields():
    if request.method == "POST":
        # get which option selected: X or +
        saved_keys = []
        saved_vals = []
        decision = ""
        decision_key = ""
        attr_name = ""
        action = ""
        field_type = ""
        last_index = 0

        saved_key_val_pairs = []

        for key in request.form:
            val = request.form[key]
            print("{0}, {1}".format(key, val))
            if "decision" in key:
                decision = val
                decision_key = key
                print("DECISION: {0}".format(decision_key))

            elif "attr_name" in key:
                attr_name = val
                print("ATTR: {0}".format(attr_name))

            elif "field_type" in key:
                field_type = val
                print("FIELD_TYPE: {0}".format(field_type))

            else:
                # if val.endswith("/"):
                #     val = val[0:-1]
                # if key.endswith("/"):
                #     key = key[0:-1]
                # print("STRIPPED VAL: '{0}'".format(val))
                saved_keys.append(key)
                saved_vals.append(val)
        
        if "delete" in decision_key:
            action = "delete"
            attr_to_delete = decision_key[len("decision_delete_"):]
            print("ATTR TO DELETE: {0}".format(attr_to_delete))
            del_index = saved_keys.index(attr_to_delete)
            del saved_keys[del_index]
            del saved_vals[del_index]

        else:
            action = "add"
            
        for i in range(0, min(len(saved_keys), len(saved_vals))):
            saved_key_val_pairs.append([saved_keys[i], saved_vals[i]])
        
    else:
        field_type = "text"
        action = "initialize"
        saved_key_val_pairs = []
        saved_key_val_pairs.append(["dm_id_0", '0th-value'])
        saved_key_val_pairs.append(["dm_id_1", '1st value'])
        saved_key_val_pairs.append(["dm_id_2", '2nd value'])
        saved_key_val_pairs.append(["dm_id_3", '3rd value'])
        attr_name = "dm_id"
        # length = len(saved_key_val_pairs)
    # TODO: rather than length, should have a "last unique id" value
    # length = len(saved_key_val_pairs)
    last_attr = saved_key_val_pairs[len(saved_key_val_pairs) - 1][0]
    attr_prefix = "{0}_".format(attr_name)
    length = int(last_attr[len(attr_prefix):]) + 1
    print("LENGTH: {0}".format(length))

    return render_template('dynamic_fields.html', attr_name=attr_name, action=action, field_type=field_type, saved_val=saved_key_val_pairs, length=length)
            


if __name__ == '__main__':
    # debug=True makes it so that all changes made it editor
    # are immediately reflected in the running application
    # without requiring the server to be stopped and restarted
    app.run(debug=True)