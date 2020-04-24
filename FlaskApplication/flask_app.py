from flask import Flask, render_template, request, redirect
# from flask_mysqldb import MySQL
import mysql.connector
import yaml

app = Flask(__name__)

# configure db
connection_values = yaml.load(open('db.yaml'))

# add try-except for db

# app.config['MYSQL_HOST'] = db['mysql_host']
# app.config['MYSQL_USER'] = db['mysql_user']
# app.config['MYSQL_PASSWORD'] = ['mysql_password']
# app.config['MYSQL_DB'] = ['mysql_db']

# mysql = MySQL(app)

@app.route('/', methods=['GET', 'POST'])
def index():
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
    return render_template('index.html')


@app.route('/players')
def players():
    db = connect()
    cursor = db.cursor()
    result = cursor.execute("SELECT * FROM player")
    playerDetails = cursor.fetchall()
    if len(playerDetails) > 0:
        return render_template('players.html', playerDetails=playerDetails)

def connect():
    db = mysql.connector.connect(
            host=connection_values['mysql_host'],
            user=connection_values['mysql_user'],
            passwd=connection_values['mysql_password'],
            database=connection_values['mysql_db']
        )

    return db


if __name__ == '__main__':
    # debug=True makes it so that all changes made it editor
    # are immediately reflected in the running application
    # without requiring the server to be stopped and restarted
    app.run(debug=True)