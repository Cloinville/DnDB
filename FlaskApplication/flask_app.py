from flask import Flask, render_template, request, redirect, url_for
# from flask_mysqldb import MySQL
import mysql.connector
import yaml
import re
import json

app = Flask(__name__)

# configure db
connection_values = yaml.load(open('db.yaml'))
logged_in_user = None
default_dropdown_str = ""
searchable_entities = ['Monster', 'Class', 'Race', 'Spell', 'Item']

# add try-except for db

@app.route('/login', methods=['GET', 'POST'])
def login():
    if logged_in_user != None:
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
    if logged_in_user != None:
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
    if logged_in_user == None:
        return redirect('/login')
    return render_template('index.html')


@app.route('/my_campaigns', methods=['POST', 'GET'])
def my_campaigns():
    if logged_in_user == None:
        return redirect('/login')

    # If campaign preview picked, send campaign_details the id of the selected campaign
    # to be used to generate the public/private details of that result
    if request.method == 'POST':        
        campaign_id = request.form['campaign_btn']
        return redirect(url_for('campaign_details', campaign_id=campaign_id))

    # Otherwise, render page with campaign previews
    campaign_preview_details = execute_cmd_and_get_result("CALL get_campaign_previews('{0}')".format(logged_in_user))

    return render_template('my_campaigns.html', campaign_preview_details=campaign_preview_details)


# TODO: 4/25: actually implement
@app.route('/campaign_details')
def campaign_details():
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

    return render_template('campaign_details.html', campaign_details=campaign_details)


#TODO: stub
@app.route('/my_creations')
def my_creations():
    return render_template('my_creations.html')


#TODO: stub
@app.route('/create')
def create():
    return render_template('create.html')


@app.route('/search', methods=['GET', 'POST'])
def search():
    if logged_in_user == None:
        return redirect('/index')

    if request.method == 'POST':
        chosen_entity = request.form['chosen_entity']
        search_fields_url = "search_fields_template/{0}".format(chosen_entity.lower())
        print(chosen_entity)

        return render_template('search.html', entities=searchable_entities, chosen_entity=chosen_entity, search_fields_link=search_fields_url)
    return render_template('search.html', entities=searchable_entities, chosen_entity=searchable_entities[0], search_fields_link=None)


@app.route('/search_fields_template/<name>', methods=['GET', 'POST'])
def search_fields_template(name):
    chosen_entity = name
   # TODO: Finish POST request handling
    if request.method == "POST":
        # Showing how can access the key and value of every field
        for item in request.form:
            print("Key: '{0}', Value:'{1}'".format(item, request.form[item]))
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
    for pair in foreign_key_names_and_tables:
        # foreign_key_name = pair[0]
        referenced_table = pair[1]
        # get display name for table
        referenced_table_record_names = get_display_names_for_all_records_in_table(referenced_table)
        if len(referenced_table_record_names) > 0:
            referenced_table_record_names.insert(0, default_dropdown_str)
            fk_set_list.append([referenced_table, referenced_table_record_names])

    return render_template('search_fields_template.html', alphanumeric_attr_list=alphanumeric_attr_list, enum_attr_list=enum_attr_list, fk_set_list=fk_set_list)


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
    # TODO - implement this!
    # needs to log the user into the webpage/set as current user, somehow
    global logged_in_user 
    logged_in_user = username
    return


def username_invalid(username):
    return re.search(r'[^a-zA-Z0-9_]', username)


# TODO: add password length max
def password_invalid(password):
    return re.search(r'[^a-zA-Z0-9_]', password)


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

        cursor.callproc(procedure_name, procedure_args)
        result = []
        for stored_result in cursor.stored_results():
            curr_result_lists = stored_result.fetchall()
            for result_list in curr_result_lists:
                result.append(result_list)
    else:
        cursor.execute(cursor_cmd)
        result = cursor.fetchall()

    cursor.close()
    db.close()

    return result


# TODO: refactor code to use this as replacement
def execute_cmd(cursor_cmd):
    db = connect()
    cursor = db.cursor()

    cursor.execute(cursor_cmd)

    cursor.close()
    db.close()


def get_display_name_select_statement_as_str(entity):
    try:
        result = execute_cmd_and_get_result("SELECT get_display_name_select_statement('{0}')".format(entity))
        return result[0][0]
    except:
        return ""


def get_display_names_for_all_records_in_table(entity):
    try:
        select_statement = get_display_name_select_statement_as_str(entity)
        raw_display_names = execute_cmd_and_get_result(select_statement)
        formatted_display_names = []
        for name in raw_display_names:
            formatted_display_names.append(name[0])
        return formatted_display_names
    except:
        return []


if __name__ == '__main__':
    # debug=True makes it so that all changes made it editor
    # are immediately reflected in the running application
    # without requiring the server to be stopped and restarted
    app.run(debug=True)