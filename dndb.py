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

# #Item & Weapon
# with open ("src/5e-SRD-Equipment.json", 'r',encoding='utf-8') as dndFile:
#     data = json.load(dndFile)
#     i = 0
#     while i < len(data):
#         desc = ""
#         try:
#             desc = str(data[i]['desc'])[2:-2]
#         except:
#             desc = ""
#         #print('INSERT INTO item (item_id,item_name,item_description,item_price,dm_id) VALUES (' + str(i) + ',\'' + str(data[i]['name']) + '\',\'' + desc + '\',\'' + str(data[i]["cost"]["quantity"]) + '\',NULL)')
#         if(str(data[i]['equipment_category']) == "Weapon"):
#             try:
#                 print('INSERT INTO weapon (weapon_id,weapon_num_dice_to_roll,weapon_damage_modifier,weapon_range,damage_type,item_id) VALUES ('+str(i)+',\''+str(data[i]['damage']['damage_dice'])+'\',0,\''+str(data[i]['range']['normal'])+'\',\''+str(data[i]['damage']['damage_type']['name'])+'\','+ str(i)+')')
#             except: 
#                 print("Row not added due to formatting error")
#         i+=1
# dndFile.close()

# #Language
# with open ("src/5e-SRD-Languages.json", 'r',encoding='utf-8') as dndFile:
#     data = json.load(dndFile)
#     i = 0
#     while i < len(data):
#         try:
#             print('INSERT INTO language (language_id,language_name) VALUES (' + str(i) + ',\'' + str(data[i]['name']) +'\')')
#         except: 
#             print("Row not added due to formatting error")
#         i+=1
# dndFile.close()

# #School of Magic
# with open ("src/5e-SRD-Magic-Schools.json", 'r',encoding='utf-8') as dndFile:
#     data = json.load(dndFile)
#     i = 0
#     while i < len(data):
#         try:
#             print('INSERT INTO schoolofmagic (magicschool_id,magicschool_name,magicschool_description ) VALUES (' + str(i) + ',\'' + str(data[i]['name']) +'\',\'' + str(data[i]['desc']) + '\')')
#         except: 
#             print("Row not added due to formatting error")
#         i+=1
# dndFile.close()

# #Monster
# with open ("src/5e-SRD-Monsters.json", 'r',encoding='utf-8') as dndFile:
#     data = json.load(dndFile)
#     i = 0
#     while i < len(data):
#         try:
#             print('INSERT INTO monster (monster_id,monster_name,monster_challenge_rating,monster_base_hp,monster_type,dm_id ) VALUES (' + str(i) + ',\'' + str(data[i]['name']) +'\',' + str(data[i]['challenge_rating']) + ',' + str(data[i]['hit_points']) + ',' + str(data[i]['type']) + ',NULL)')
#         except: 
#             print("Row not added due to formatting error")
#         i+=1
# dndFile.close()

# #Race
# with open ("src/5e-SRD-Races.json", 'r',encoding='utf-8') as dndFile:
#     data = json.load(dndFile)
#     i = 0
#     while i < len(data):
#         try:
#             print('INSERT INTO race (race_id,race_is_playable,race_name,race_speed,race_size,dm_id ) VALUES (' + str(i) + ',True,\'' + str(data[i]['name']) + '\',' + str(data[i]['speed']) + ',\'' + str(data[i]['size']) + '\',NULL)')
#         except: 
#             print("Row not added due to formatting error")
#         i+=1
# dndFile.close()

# #Skill
# with open ("src/5e-SRD-Skills.json", 'r',encoding='utf-8') as dndFile:
#     data = json.load(dndFile)
#     i = 0
#     while i < len(data):
#         try:
#             ability_id = -1
#             if str(data[i]['ability_score']['name']) == "STR":
#                 ability_id = 0
            
#             if str(data[i]['ability_score']['name']) == "DEX":
#                 ability_id = 1
            
#             if str(data[i]['ability_score']['name']) == "CON":
#                 ability_id = 2
            
#             if str(data[i]['ability_score']['name']) == "INT":
#                 ability_id = 3
            
#             if str(data[i]['ability_score']['name']) == "WIS":
#                 ability_id = 4
            
#             if str(data[i]['ability_score']['name']) == "CHA":
#                 ability_id = 5
            
#             print('INSERT INTO skill (skill_id,skill_name,skill_description,skill_is_trained_only,ability_id) VALUES('+str(i)+',\''+str(data[i]['name'])+'\',\''+str(data[i]['desc'])[2:-2]+'\',False,'+str(ability_id)+')')
#         except: 
#             print("Row not added due to formatting error")
#         i+=1
# dndFile.close()

# #Spell
# with open ("src/5e-SRD-Spells.json", 'r',encoding='utf-8') as dndFile:
#     data = json.load(dndFile)
#     i = 0
#     while i < len(data):
#         try:
#             magic_id = -1
#             if str(data[i]['school']['name']) == "Abjuration":
#                 magic_id = 0
            
#             if str(data[i]['school']['name']) == "Conjuration":
#                 magic_id = 1
            
#             if str(data[i]['school']['name']) == "Divination":
#                 magic_id = 2
            
#             if str(data[i]['school']['name']) == "Enchantment":
#                 magic_id = 3
            
#             if str(data[i]['school']['name']) == "Evocation":
#                 magic_id = 4
            
#             if str(data[i]['school']['name']) == "Illusion":
#                 magic_id = 5
            
#             if str(data[i]['school']['name']) == "Necromancy":
#                 magic_id = 6
            
#             if str(data[i]['school']['name']) == "Transmutation":
#                 magic_id = 7
#             print('INSERT INTO spell (spell_id,spell_name,spell_description,spell_min_level,spell_range,spell_casting_time,spell_duration,spell_is_concentration,magicschool_id,dm_id ) VALUES ('+str(i)+',\''+str(data[i]['name'])+'\','+json.dumps(str(data[i]['desc'])[2:-2]) + ',' + str(data[i]['level']) + ',\'' + str(data[i]['range']) + '\',\'' + str(data[i]['casting_time']) + '\',\'' + str(data[i]['duration']) + '\',' + str(data[i]['concentration']) + ',' + str(magic_id) + ',NULL)')
#         except: 
#             print("Row not added due to formatting error")
#         i+=1
# dndFile.close()


# mydb.commit()
cursor.close()
print ("Done")