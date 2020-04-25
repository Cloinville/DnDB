from flask import Flask, render_template, request, redirect
# from flask_mysqldb import MySQL
import mysql.connector
import yaml
import re

app = Flask(__name__)

# configure db
connection_values = yaml.load(open('db.yaml'))
logged_in_user = None

# add try-except for db

# app.config['MYSQL_HOST'] = db['mysql_host']
# app.config['MYSQL_USER'] = db['mysql_user']
# app.config['MYSQL_PASSWORD'] = ['mysql_password']
# app.config['MYSQL_DB'] = ['mysql_db']

# mysql = MySQL(app)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if logged_in_user != None:
        return redirect('/index')
    error = None
    # Post means you're submitting info
    if request.method == 'POST':
        db = connect()
        playerDetails = request.form
        # username = playerDetails['username']
        # password = playerDetails['password']

        # possibility: do checking currently accomplished in signup.js here, and add text to the fields that highlight red on html side, but are originally hidden
        cursor = db.cursor()
        # TODO: update this to include password check!
        cursor.execute("SELECT * FROM player WHERE player.player_username = '{0}' LIMIT 1".format(playerDetails['username']))
        # cursor.execute("SELECT * FROM players WHERE player.username = '{0}' AND player.password = '{1}' LIMIT 1".format(playerDetails['username'], playerDetails['password']))
        result = cursor.fetchall()
        if len(result) > 0:
            # got a match => can log in and go to home
            player_login(playerDetails['username'])
            cursor.close()
            db.close()
            return redirect('/index')
        else:
            # show fields??
            error = "Incorrect username or password. Please try again."
            # error - no match
        # cursor.execute("INSERT INTO player(player_username, player_nickname) VALUES('{0}', '{1}')".format(playerDetails['username'], playerDetails['nickname']))
        # db.commit()
        # get 
        cursor.close()
        db.close()
    # else:
    #     # must have clicked the link??
    #     type_requested = request.args.type
    #     if type_requested == "redirect_to_signup":
    #         return redirect('/signup')
        # return what's being gotten I have no clue
    return render_template('login.html', error=error)


@app.route('/signup', methods=['POST', 'GET'])
def signup():
    error = None
    if request.method == 'POST':
        # trying to sign up
        player_details = request.form
        username = player_details['username']
        password = player_details['password']
        password_confirm = player_details['password_confirm']

        if username_invalid(username):
            error = "Username can only contain alphanumerics and underscores. Please try again."
        elif password_invalid(password):
            error = "Password can only contain alphanumerics and underscores. Please try again."
        elif password != password_confirm:
            error = "Passwords don't match. Please try again"
        else:
            db = connect()
            cursor = db.cursor()
            cursor.execute("SELECT * FROM player WHERE player.player_username = '{0}' LIMIT 1".format(username))
            result = cursor.fetchall()
            
            if len(result) > 0:
                error = "Username already exists. Please try again."
            else:
                # TODO: edit to add in nickname and password to insert
                cursor.execute("INSERT INTO player(player_username) VALUES('{0}')".format(username))
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


# TODO: delete this eventually
@app.route('/beta_index', methods=['GET', 'POST'])
def beta_index():
    if request.method == 'POST':
        # fetch form data
        db = connect()
        playerDetails = request.form
        nickname = playerDetails['nickname']
        username = playerDetails['username']

        cursor = db.cursor()
        cursor.execute("INSERT INTO player(player_username, player_nickname) VALUES('{0}', '{1}')".format(playerDetails['username'], playerDetails['nickname']))
        db.commit()
        cursor.close()
        db.close()
        return redirect('/players')
    return render_template('beta_index.html')


# TODO: delete this eventually
@app.route('/players')
def players():
    db = connect()
    cursor = db.cursor()
    result = cursor.execute("SELECT * FROM player")
    playerDetails = cursor.fetchall()
    if len(playerDetails) > 0:
        return render_template('players.html', playerDetails=playerDetails)


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
    return re.search(r'[^a-zA-Z0-9_]', username) != None or len(username) > 32


# TODO: add password length max
def password_invalid(password):
    return re.search(r'[^a-zA-Z0-9_]', password) != None


if __name__ == '__main__':
    # debug=True makes it so that all changes made it editor
    # are immediately reflected in the running application
    # without requiring the server to be stopped and restarted
    app.run(debug=True)