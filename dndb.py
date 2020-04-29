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
#             print('INSERT INTO class (class_id,class_name,class_description,class_hit_die) VALUES (' + str(i) + ',\'' + str(data[i]['name']) + '\',NULL,\'d' + str(data[i]['hit_die']) + '\')')
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
#         print('INSERT INTO item (item_id,item_name,item_description,item_price,dm_id) VALUES (' + str(i) + ',\'' + str(data[i]['name']) + '\',\'' + desc + '\',\'' + str(data[i]["cost"]["quantity"]) + '\',NULL)')
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
#             print('INSERT INTO language (language_id,language_name,language_description) VALUES (' + str(i) + ',\'' + str(data[i]['name']) +'\',NULL)')
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
#             print('INSERT INTO monster (monster_id,monster_name,monster_ac,monster_challenge_rating,monster_description,monster_base_hp,monster_type,dm_id) VALUES (' + str(i) + ',\'' + str(data[i]['name']) +'\','+ str(data[i]['armor_class']) + ','+ str(data[i]['challenge_rating']) + ',NULL,' + str(data[i]['hit_points']) + ',' + str(data[i]['type']) + ',NULL)')
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
#             print('INSERT INTO race (race_id,race_is_playable,race_name,race_description,race_speed,race_size,dm_id ) VALUES (' + str(i) + ',True,\'' + str(data[i]['name']) + '\',NULL,' + str(data[i]['speed']) + ',\'' + str(data[i]['size']) + '\',NULL)')
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

#             material = ""
#             try:
#                 material = str(data[i]['material'])[1:-1]
#             except:
#                 material = ""
#             print('INSERT INTO spell (spell_id,spell_name,spell_description,spell_min_level,spell_range,spell_casting_time,spell_duration,spell_is_concentration,spell_material,magicschool_id,dm_id ) VALUES ('+str(i)+',\''+str(data[i]['name'])+'\','+json.dumps(str(data[i]['desc'])[2:-2]) + ',' + str(data[i]['level']) + ',\'' + str(data[i]['range']) + '\',\'' + str(data[i]['casting_time']) + '\',\'' + str(data[i]['duration']) + '\',' + str(data[i]['concentration']) + ',\''+str(material) +'\',' + str(magic_id) + ',NULL)')
#         except: 
#             print("Row not added due to formatting error")
#         i+=1
# dndFile.close()

# #Class Level New Spells Count
# with open ("src/5e-SRD-Levels.json", 'r',encoding='utf-8') as dndFile:
#     data = json.load(dndFile)
#     i = 0
#     while i < len(data):
#         try:
#             print('INSERT INTO classlevelnewspellscount (class_id,newspellscount_class_level,newspellscount_cantrips,newspellscount_spells,newspellscount_spell_slots_level_1,newspellscount_spell_slots_level_2 ,newspellscount_spell_slots_level_3 ,newspellscount_spell_slots_level_4 ,newspellscount_spell_slots_level_5 ,newspellscount_spell_slots_level_6 ,newspellscount_spell_slots_level_7 ,newspellscount_spell_slots_level_8 ,newspellscount_spell_slots_level_9) VALUES (' + str(int(i/20)) + ',' + str(data[i]['level'])+',\'' + str(data[i]['spellcasting']['cantrips_known']) + '\','+ str(data[i]['spellcasting']['spells_known']) +',' + str(data[i]['spellcasting']['spell_slots_level_1']) + ',' + str(data[i]['spellcasting']['spell_slots_level_2']) + ','+ str(data[i]['spellcasting']['spell_slots_level_3']) + ','+ str(data[i]['spellcasting']['spell_slots_level_4']) + ',' + str(data[i]['spellcasting']['spell_slots_level_5']) + ','+ str(data[i]['spellcasting']['spell_slots_level_6']) + ','+str(data[i]['spellcasting']['spell_slots_level_7']) + ','+str(data[i]['spellcasting']['spell_slots_level_8']) + ','+str(data[i]['spellcasting']['spell_slots_level_9']) + ')')
#         except: 
#             print("HOPEFULLY YOU ARE READING THIS BECAUSE THE CODE WORKS PERFECTLY AND THIS IS A FAIL FOR NOT EXISTING WITH THE DATA :)")
#         i+=1
# dndFile.close()

# #Race Languages
# with open ("src/5e-SRD-Races.json", 'r',encoding='utf-8') as dndFile:
#     data = json.load(dndFile)
#     i = 0
#     while i < len(data):
#         j = 0
#         while j < len(data[i]['languages']):
#             lang_id = -1
#             if str(data[i]['languages'][j]['name']) == "Common":
#                 lang_id = 0
            
#             if str(data[i]['languages'][j]['name']) == "Dwarvish":
#                 lang_id = 1
            
#             if str(data[i]['languages'][j]['name']) == "Elvish":
#                 lang_id = 2
            
#             if str(data[i]['languages'][j]['name']) == "Giant":
#                 lang_id = 3
            
#             if str(data[i]['languages'][j]['name']) == "Gnomish":
#                 lang_id = 4
            
#             if str(data[i]['languages'][j]['name']) == "Goblin":
#                 lang_id = 5
            
#             if str(data[i]['languages'][j]['name']) == "Halfling":
#                 lang_id = 6
            
#             if str(data[i]['languages'][j]['name']) == "Orc" or str(data[i]['languages'][j]['name']) == "Orcish":
#                 lang_id = 7

#             if str(data[i]['languages'][j]['name']) == "Abyssal":
#                 lang_id = 8
            
#             if str(data[i]['languages'][j]['name']) == "Celestial":
#                 lang_id = 9
            
#             if str(data[i]['languages'][j]['name']) == "Draconic":
#                 lang_id = 10
            
#             if str(data[i]['languages'][j]['name']) == "Deep Speech":
#                 lang_id = 11
            
#             if str(data[i]['languages'][j]['name']) == "Infernal":
#                 lang_id = 12
            
#             if str(data[i]['languages'][j]['name']) == "Primordial":
#                 lang_id = 13
            
#             if str(data[i]['languages'][j]['name']) == "Sylvan":
#                 lang_id = 14
            
#             if str(data[i]['languages'][j]['name']) == "Undercommon":
#                 lang_id = 15
#             try:
#                 print('INSERT INTO raceknownlanguage (race_id,language_id) VALUES ('+str(i)+','+str(lang_id) +')')
#             except: 
#                 print("Row not added due to formatting error")
#             j+=1
#         j = 0
#         try:
#             while j < len(data[i]['language_options']['from']):
#                 lang_id = -1
#                 if str(data[i]['language_options']['from'][j]['name']) == "Common":
#                     lang_id = 0
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Dwarvish":
#                     lang_id = 1
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Elvish":
#                     lang_id = 2
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Giant":
#                     lang_id = 3
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Gnomish":
#                     lang_id = 4
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Goblin":
#                     lang_id = 5
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Halfling":
#                     lang_id = 6
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Orc":
#                     lang_id = 7

#                 if str(data[i]['language_options']['from'][j]['name']) == "Abyssal":
#                     lang_id = 8
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Celestial":
#                     lang_id = 9
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Draconic":
#                     lang_id = 10
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Deep Speech":
#                     lang_id = 11
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Infernal":
#                     lang_id = 12
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Primordial":
#                     lang_id = 13
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Sylvan":
#                     lang_id = 14
                
#                 if str(data[i]['language_options']['from'][j]['name']) == "Undercommon":
#                     lang_id = 15
#                 try:
#                     print('INSERT INTO raceknownlanguage (race_id,language_id) VALUES ('+str(i)+','+str(lang_id) +')')
#                 except: 
#                     print("Row not added due to formatting error")
#                 j+=1
#         except:
#             print("No language option")    
#         i+=1
# dndFile.close()

# #Class Learnable Spell
# with open ("src/5e-SRD-Spells.json", 'r',encoding='utf-8') as dndFile:
#     data = json.load(dndFile)
#     i = 0
#     while i < len(data):
#         j = 0
#         while j < len(data[i]['classes']):
#             class_id = -1
#             if str(data[i]['classes'][j]['name']) == "Barbarian":
#                 class_id = 0
            
#             if str(data[i]['classes'][j]['name']) == "Bard":
#                 class_id = 1
            
#             if str(data[i]['classes'][j]['name']) == "Cleric":
#                 class_id = 2
            
#             if str(data[i]['classes'][j]['name']) == "Druid":
#                 class_id = 3
            
#             if str(data[i]['classes'][j]['name']) == "Fighter":
#                 class_id = 4
            
#             if str(data[i]['classes'][j]['name']) == "Monk":
#                 class_id = 5

#             if str(data[i]['classes'][j]['name']) == "Paladin":
#                 class_id = 6
            
#             if str(data[i]['classes'][j]['name']) == "Ranger":
#                 class_id = 7
            
#             if str(data[i]['classes'][j]['name']) == "Rogue":
#                 class_id = 8
            
#             if str(data[i]['classes'][j]['name']) == "Sorcerer":
#                 class_id = 9
            
#             if str(data[i]['classes'][j]['name']) == "Warlock":
#                 class_id = 10
            
#             if str(data[i]['classes'][j]['name']) == "Wizard":
#                 class_id = 11
            
#             try:
#                 print('INSERT INTO classlearnablespell (spell_id,class_id,cls_required_class_level) VALUES (' + str(i) + ',' + str(class_id) +','+ str(data[i]['level']) +')')
#             except: 
#                 print("Row not added due to formatting error")
#             j+=1
#         i+=1
# dndFile.close()

# mydb.commit()
cursor.close()
print ("Done")