import mysql.connector
import os
import json

mydb = mysql.connector.connect(host='csuci-kloomis.cikeys.com',
    user='csuciklo_dndb_root',
    passwd='WeareabsolutelygonnagetanA+',
    database='csuciklo_dndb')
cursor = mydb.cursor()

# #Ability
# with open ("src/5e-SRD-Ability-Scores.json", 'r',encoding='utf-8') as ability_file:
#     data = json.load(ability_file)
#     i = 0
#     while i < len(data):
#         try:
#             print('INSERT INTO ability (ability_id,ability_name,ability_description) VALUES (' + str(i) + ',\'' + str(data[i]['full_name']) + '\',\'' + str(data[i]['desc'])[2:-2] + '\')')
#         except: 
#             print("Row not added due to formatting error")
#         i+=1
# ability_file.close()

# #Class
# with open ("src/5e-SRD-Classes.json", 'r',encoding='utf-8') as class_file:
#     data = json.load(class_file)
#     i = 0
#     while i < len(data):
#         try:
#             print('INSERT INTO class (class_id,class_name,class_hit_die) VALUES (' + str(i) + ',\'' + str(data[i]['name']) + '\',\'' + str(data[i]['hit_die']) + '\')')
#         except: 
#             print("Row not added due to formatting error")
#         i+=1
# class_file.close()

# #DamageType
# with open ("src/5e-SRD-Damage-Types.json", 'r',encoding='utf-8') as damage_file:
#     data = json.load(damage_file)
#     i = 0
#     while i < len(data):
#         try:
#             print('INSERT INTO damagetype (damage_type_id ,damage_type_name ,damage_type_description ) VALUES (' + str(i) + ',\'' + str(data[i]['name']) + '\',\'' + str(data[i]['desc'])[2:-2] + '\')')
#         except: 
#             print("Row not added due to formatting error")
#         i+=1
# damage_file.close()

#Item & Weapon
with open ("src/5e-SRD-Equipment.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        desc = ""
        try:
            desc = str(data[i]['desc'])[2:-2]
        except:
            desc = ""
        #print('INSERT INTO item (item_id,item_name,item_description,item_price,dm_id) VALUES (' + str(i) + ',\'' + str(data[i]['name']) + '\',\'' + desc + '\',\'' + str(data[i]["cost"]["quantity"]) + '\',NULL)')
        if(str(data[i]['equipment_category']) == "Weapon"):
            try:
                print('INSERT INTO weapon (weapon_id,weapon_num_dice_to_roll,weapon_damage_modifier,weapon_range,damage_type,item_id) VALUES ('+str(i)+',\''+str(data[i]['damage']['damage_dice'])+'\',0,\''+str(data[i]['range']['normal'])+'\',\''+str(data[i]['damage']['damage_type']['name'])+'\','+ str(i)+')')
            except: 
                print("Row not added due to formatting error")
        i+=1
dndFile.close()

# mydb.commit()
cursor.close()
print ("Done")