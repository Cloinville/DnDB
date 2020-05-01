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
        for key in request.form:
            print("{0} : {1}".format(key, request.form[key]))
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


#TODO: stub
@app.route('/create')
def create():
    if logged_in_user_details['username'] == None:
        return redirect('/login')

    return render_template('create.html', logged_in_user_details=logged_in_user_details)


@app.route('/search', methods=['GET', 'POST'])
def search():
    # if logged_in_user == None:
    if logged_in_user_details['username'] == None:
        return redirect('/login')

    if request.method == 'POST':
        chosen_entity = request.form['chosen_entity']
        search_fields_url = "search_fields_template/{0}".format(chosen_entity.lower())
        print(chosen_entity)

        return render_template('search.html', entities=searchable_entities, chosen_entity=chosen_entity, search_fields_link=search_fields_url, logged_in_user_details=logged_in_user_details)
    return render_template('search.html', entities=searchable_entities, chosen_entity=searchable_entities[0], search_fields_link=None, logged_in_user_details=logged_in_user_details)


# removed 'POST' option in test 4/27 , methods=['GET', 'POST']
@app.route('/search_fields_template/<name>')
def search_fields_template(name):
    chosen_entity = name
   # TODO: Finish POST request handling
    # if request.method == "POST":
    #     # Showing how can access the key and value of every field
    #     search_fields = []
    #     for item in request.form:
    #         key = item
    #         value = request.form[item]
    #         if value != "":
    #             search_fields.append([key, value])
        
    #     session['search_fields'] = search_fields
    #     return redirect(url_for('search_result'))
        
        # TODO 4/26: add final REDIRECT function, to reroute the results of the 
        #            SELECT statement created using these key-values into search results page
        # ie. return redirect(url_for('search_results', query=query))       

    attr_datatype_list = execute_cmd_and_get_result("CALL get_non_foreign_key_column_names_and_datatypes('{0}')".format(chosen_entity))
    alphanumeric_attr_list = []
    enum_attr_list = []
    for attr_set in attr_datatype_list:
        attr_name = attr_set[0]
        attr_datatype = attr_set[1]

        #NOTE: might need add .lower() to datatype
        if "enum" in attr_datatype:
            enum_vals = attr_datatype.split("enum")[1][1:-1].split(",")
            enum_vals.insert(0, default_dropdown_str)
            enum_attr_list.append([attr_name, enum_vals])
        else:
            if "text" not in attr_datatype:
                alphanumeric_attr_list.append(attr_name)

    foreign_key_names_and_tables = execute_cmd_and_get_result("CALL get_foreign_key_column_names_and_referenced_table_names('{0}')".format(chosen_entity))
    fk_set_list = []
    # For each foreign table that the base table references
    for pair in foreign_key_names_and_tables:
        # Get the name of the table
        referenced_table = pair[1]
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
            print("KEY VALUE: '{0}', '{1}'".format(key,value))
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
        for key in request.form:
            if "_btn" in key:
                post_key = key
                post_value = request.form[key]
                print("YUP: {0}, {1}".format(key, request.form[key]))
            else:
                print("nope: {0}, {1}".format(key, request.form[key]))

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
        print("UPDATED NICKNAME: {0}".format(updated_nickname))
        logged_in_user_details['nickname'] = updated_nickname


def username_invalid(username):
    return re.search(r'[^a-zA-Z0-9_]', username)


# TODO: add password length max
def password_invalid(password):
    return re.search(r'[^a-zA-Z0-9_]', password)


# def get_player_id():
#     # player_id = execute_cmd_and_get_result("SELECT get_player_id_from_username('{0}')".format(logged_in_user))[0][0]
#     return player_id


# def get_dm_id():
#     dm_id = execute_cmd_and_get_result("CALL get_dm_id_for_player('{0}')".format(logged_in_user))


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


# TODO: refactor code to use this as replacement
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
        print("FIELD UPDATE: CALL update_field_in_table('{0}', '{1}', '{2}', '{3}')".format(entity, field, new_value, condition))
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

# def get_unique_display_names_and_cols_for_all_records_in_table(entity):
    # try:
    #     select_statement = get_display_and_column_names_select_statement_as_str(entity)
    #     raw_display_names = execute_cmd_and_get_result(select_statement)
    #     formatted_display_names = []
    #     for name in raw_display_names:
    #         formatted_name = name[0]
    #         formatted_col = name[1]
    #         if formatted_name not in formatted_display_names:
    #             formatted_display_names.append([formatted_name, formatted_col])
    #     return formatted_display_names
    # except:
    #     return []


def get_formatted_previews_and_metadata_list(unformatted_records):
    # unformatted_records, even if no search results, will ALWAYS have
    # at least one entry
    print("UNFORMATTED: '{0}'".format(unformatted_records))
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
            print("identifier_pair: {0}".format(curr_record_identifier_metadata_pair))

        for i in range(1, min(2, end_index)):
            curr_record_table_name = record[i]
            print("table_name: {0}".format(curr_record_table_name))

        for i in range(2, min(3, end_index)):
            curr_record_identifier_pair = [column_names_list[i], record[i]]
            print("col_val_pair: {0}".format(curr_record_identifier_pair))

        # for i in range(3, min(4, end_index)):
        #     curr_record_headliner_col_val_pair = [column_names_list[i], record[i]]
        #     print("headliner pair: {0}".format(curr_record_headliner_col_val_pair))

        # for i in range(4, end_index):
        #     curr_record_column_value_pairs.append([column_names_list[i], record[i]])

        for i in range(3, end_index):
            curr_record_column_value_pairs.append([column_names_list[i], record[i]])
        
        formatted_records.append([curr_record_table_name, curr_record_identifier_metadata_pair, curr_record_identifier_pair, curr_record_column_value_pairs])
    
    if len(formatted_records) == 0:
        formatted_records = None

    return formatted_records


if __name__ == '__main__':
    # debug=True makes it so that all changes made it editor
    # are immediately reflected in the running application
    # without requiring the server to be stopped and restarted
    app.run(debug=True)