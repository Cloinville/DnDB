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
searchable_entities = ['Monster', 'Class', 'Race', 'Spell', 'Item']
creatable_entities = ['character', 'campaign', 'monster', 'item', 'weapon', 'spell', 'monsterparty']

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

    # username = logged_in_user
    # nickname = logged_in_user_nickname
    # username = logged_in_user_details['username']
    # nickname = logged_in_user_details['nickname']

    return render_template('profile.html', error=error, logged_in_user_details=logged_in_user_details)


@app.route('/premium', methods=['GET', 'POST'])
def premium():
    # if logged_in_user == None:
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

    chosen_entity = entity

    include_text_attrs = True
    alphanumeric_attr_list, enum_attr_list = get_alphanumeric_and_enum_attr_lists(chosen_entity, include_text_attrs)

    include_creator_id = False
    fk_set_list = get_fk_set_list(chosen_entity, include_creator_id)

    # TODO 5/1: determine which associative tables to include, and add fields for those
    #           a. Need to distinguish between those w/set number, and those that are dynamic
    #           b. AND for those that are dynamic, need way for users to increase # of fields

    if request.method == "POST":
        if request.form['submit_btn'] == "Quit":
            return redirect('/index')
        else:
            for key in request.form:
                print("{0}, {1}".format(key, request.form[key]))
    # 1. Get all fields directly in the record of that entity
    # 2. Get all foreign fields
    #    a. If DM_ID, DON'T SHOW
    #    b. Else, do drop down thing from search
    # 3. Options for associative records
    #

    return render_template('create_details.html', chosen_entity=entity, alphanumeric_attr_list=alphanumeric_attr_list, enum_attr_list=enum_attr_list, fk_set_list=fk_set_list, logged_in_user_details=logged_in_user_details)


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

    # TODO: this is currently kind of arbitrary. Remove?      
    include_text_attrs = False

    include_creator_id = True

    alphanumeric_attr_list, enum_attr_list = get_alphanumeric_and_enum_attr_lists(chosen_entity, include_text_attrs)

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
        # records = []
        # num_cols = len(columns)

        # for result in results:
        #     curr_col_and_val = []
        #     end_index = min(len(result), num_cols)
        #     for i in range(0, end_index):
        #         curr_col_and_val.append([columns[i][0], result[i]])
        #     records.append(curr_col_and_val)

        # print("COLS AND VALS: ")
        # for col_and_val in records:
        #     print("1: {0}".format(col_and_val))

        # if len(records) == 0:
        #     records = None

    # search_fields = session.pop('search_fields', [])
    # return render_template('search_result', search_fields=search_fields)
    return render_template('search_result.html', records_and_metadata=records_and_metadata, logged_in_user_details=logged_in_user_details)


#TODO: stub
@app.route('/entity_details', methods=['GET', 'POST'])
def entity_details():
    if logged_in_user_details['username'] == None:
        return redirect('/login')

    if request.method == 'POST':
        post_key = ""
        post_value = ""

        # DEBUGGING
        for key in request.form:
            if key.endswith("_btn"):
                post_key = key
                post_value = request.form[key]
                print("YUP: {0}, {1} -> need to strip off _btn from end to get chosen_entity".format(post_key, post_value))
            else:
                print("nope: {0}, {1}".format(key, request.form[key]))
        # END DEBUGGING

    return render_template('entity_details.html', logged_in_user_details=logged_in_user_details)


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


def get_alphanumeric_and_enum_attr_lists(chosen_entity, include_text_attrs):
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
            enum_vals = attr_datatype.split("enum")[1][1:-1].split(",")
            enum_vals.insert(0, default_dropdown_str)
            enum_attr_list.append([attr_name, enum_vals])
        else:
            if "text" not in attr_datatype or include_text_attrs:
                attr_datatype_html_pattern, attr_datatype_html_length = convert_mysql_datatype_to_html_datatype(attr_datatype)
                alphanumeric_attr_list.append([attr_name, attr_datatype_html_pattern, attr_datatype_html_length])

    return alphanumeric_attr_list, enum_attr_list


def get_fk_set_list(chosen_entity, include_creator):
    foreign_key_names_and_tables = execute_cmd_and_get_result("CALL get_foreign_key_column_names_and_referenced_table_names('{0}')".format(chosen_entity))
    
    # List format: [(foreign_table, fk_column_in_foreign_table, (fk_display_name, how display name was generated, fk value, fk col name in foreign table))]
    fk_set_list = []

    # For each foreign table that the base table references (given as pair: foreign key col name in base table, referenced table name)
    for pair in foreign_key_names_and_tables:
        local_fk_name = pair[0]
        referenced_table = pair[1]

        is_creator_reference = (local_fk_name.lower() == "player_id" and chosen_entity == "character") or (local_fk_name.lower() == "dm_id")

        if include_creator or not is_creator_reference:
            # Get the display and identification information for all records in that table
            referenced_table_record_names_and_metadata = get_displayname_displaycolname_fk_fkcolname_for_all_records_in_table(referenced_table)
        
            # If there were records in the table
            if len(referenced_table_record_names_and_metadata) > 0:

                # Save the name of the fk column for use in searching later
                foreign_key_col_name = referenced_table_record_names_and_metadata[0][3]

                # Insert a dummy entry, to have a "no selection" option for dropdowns
                referenced_table_record_names_and_metadata.insert(0, [default_dropdown_str, "", "", ""])
            
                # Add a new entry into the traversable set of all foreign key value dropdowns: table name, fk column name, records with embedded fk value options
                fk_set_list.append([referenced_table, foreign_key_col_name, referenced_table_record_names_and_metadata])
            
                print([referenced_table, foreign_key_col_name, referenced_table_record_names_and_metadata])

    return fk_set_list


def upgrade_player_to_dm():
    global logged_in_user_details
    if logged_in_user_details['dm_id'] == None:
        execute_cmd("INSERT INTO dungeonmaster(player_id) VALUES({0})".format(logged_in_user_details['player_id']))


# TODO: replace every other instance of execute to get fetchall() with this
def execute_cmd_and_get_result(cursor_cmd):
    result = None

    db = connect()
    cursor = db.cursor()

    # Handle stored procedure call
    if cursor_cmd.startswith("CALL "):
        procedure_name_and_args = cursor_cmd[5:]
        procedure_name, procedure_args_block = procedure_name_and_args.split("(")
        unformatted_procedure_args = procedure_args_block[:-1].split(", ")
        procedure_args = [member[1:-1] for member in unformatted_procedure_args]
        
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


def execute_cmd(cursor_cmd):
    db = connect()
    cursor = db.cursor()

    # Handle stored procedure call
    if cursor_cmd.startswith("CALL "):
        procedure_name_and_args = cursor_cmd[5:]
        procedure_name, procedure_args_block = procedure_name_and_args.split("(")
        unformatted_procedure_args = procedure_args_block[:-1].split(", ")
        procedure_args = [member[1:-1] for member in unformatted_procedure_args]
        
        # DEBUGGING
        print("procedure_name: {0} - procedure_args: {1}".format(procedure_name, procedure_args))
        # END DEBUGGING

        cursor.callproc(procedure_name, procedure_args)
    else:
        cursor.execute(cursor_cmd)

    db.commit()
    cursor.close()
    db.close()


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


@app.route('/players', methods=['GET', 'POST'])
def players():
    if request.method == "POST":
        for key in request.form:
            print("{0}, {1}".format(key, request.form[key]))
    return render_template('players.html')


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
                if val.endswith("/"):
                    val = val[0:-1]
                if key.endswith("/"):
                    key = key[0:-1]
                print("STRIPPED VAL: {0}".format(val))
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