import mysql.connector
import os
import json
import sys

mydb = mysql.connector.connect(
    host='csuci-kloomis.cikeys.com',
    user='csuciklo_ekaltman',
    passwd='comp420spring2020',
    database='csuciklo_COMP420_DnDB')
cursor = mydb.cursor()

# Create "Base Game" DM Entity to be creator of all data imported here
cursor.execute("INSERT INTO dungeonmaster(player_id) VALUES(NULL)")
dm_id = "1"

#Ability
print("Ability")
with open ("src/5e-SRD-Ability-Scores.json", 'r',encoding='utf-8') as ability_file:
    data = json.load(ability_file)
    i = 0
    while i < len(data):
        try:
            cursor.execute('INSERT INTO ability (ability_id,ability_name,ability_description) VALUES (' + str(i+1) + ',\'' + str(data[i]['full_name']) + '\',\'' + str(data[i]['desc'][0]) + '\')')
        except: 
            print(sys.exc_info())
        i+=1
ability_file.close()
print("Ability Done")

#Class
print("Class")
with open ("src/5e-SRD-Classes.json", 'r',encoding='utf-8') as class_file:
    data = json.load(class_file)
    i = 0
    while i < len(data):
        try:
            cursor.execute('INSERT INTO class (class_id,class_name,class_description,class_hit_die) VALUES (' + str(i+1) + ',\'' + str(data[i]['name']) + '\',NULL,\'d' + str(data[i]['hit_die']) + '\')')
        except: 
            print("Row not added due to formatting error: {0}".format(sys.exc_info()))
        i+=1
class_file.close()
print("Class Done")

#Item & Weapon
print("Item and Weapon Begin")
with open ("src/5e-SRD-Equipment.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        item_type = str(data[i]['equipment_category'])

        if "tools" in item_type.lower():
            item_type = "Tool"
        elif "mount" in item_type.lower() or "vehicle" in item_type.lower():
            item_type = "Mount or Vehicle"
        elif "gear" in item_type.lower() or "equipment" in item_type.lower() or "kits" in item_type.lower():
            item_type = "Equipment"
        elif "weapon" in item_type.lower():
            item_type = "Weapon"

        cursor.execute('INSERT INTO item (item_id,item_name,item_description,item_price,item_type,dm_id) VALUES('+str(i+1)+',\'' + str(data[i]['index']) + '\',\'' + 'NULL' + '\',\'' + str(data[i]["cost"]["quantity"]) + '\',\'' + item_type + '\',' + dm_id + ')')
        if(str(data[i]['equipment_category']) == "Weapon"):
            try:
                cursor.execute('INSERT INTO weapon (weapon_id,weapon_num_dice_to_roll,weapon_damage_modifier,weapon_range,damage_type,item_id) VALUES ('+str(i+1)+',\''+str(data[i]['damage']['damage_dice'])+'\',0,\''+str(data[i]['range']['normal'])+'\',\''+str(data[i]['damage']['damage_type']['name'])+'\','+ str(i+1)+')')
            except: 
                print("Row not added due to formatting error: {0}".format(sys.exc_info()))
        i+=1
dndFile.close()
print("Item and Weapon Done")

#Language
print("Language Begin")
with open ("src/5e-SRD-Languages.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        try:
            cursor.execute('INSERT INTO language (language_id,language_name,language_description) VALUES (' + str(i+1) + ',\'' + str(data[i]['name']) +'\',NULL)')
        except: 
            print("Row not added due to formatting error: {0}".format(sys.exc_info()))
        i+=1
dndFile.close()
print("Language Done")

#School of Magic
print("School of Magic Begin")
with open ("src/5e-SRD-Magic-Schools.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        try:
            #print('INSERT INTO schoolofmagic (magicschool_id,magicschool_name,magicschool_description ) VALUES (' + str(i+1) + ',\'' + str(data[i]['name']) +'\',\'' + str(data[i]['desc']) + '\')')
            cursor.execute('INSERT INTO schoolofmagic (magicschool_id,magicschool_name,magicschool_description ) VALUES (' + str(i+1) + ',\'' + str(data[i]['name']) +'\',\'' + str(data[i]['desc']) + '\')')
            #print()
        except: 
            cursor.execute('INSERT INTO schoolofmagic (magicschool_id,magicschool_name,magicschool_description ) VALUES (' + str(i+1) + ',\'' + str(data[i]['name']) +'\',\'' + 'NULL' + '\')')
        i+=1
dndFile.close()
print("School of Magic Done")

#Monster
print("Monster Begin")
with open ("src/5e-SRD-Monsters.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        try:
            cursor.execute('INSERT INTO monster (monster_id,monster_name,monster_ac,monster_challenge_rating,monster_description,monster_base_hp,monster_type,dm_id) VALUES (' + str(i+1) + ',\'' + str(data[i]['name']) +'\','+ str(data[i]['armor_class']) + ','+ str(data[i]['challenge_rating']) + ',NULL,' + str(data[i]['hit_points']) + ',\'' + str(data[i]['type']).title() + '\',' + dm_id + ')')
        except: 
            print(sys.exc_info())
        i+=1
dndFile.close()
print("Monster Done")

#Race
print("Race Begin")
with open ("src/5e-SRD-Races.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        try:
            cursor.execute('INSERT INTO race (race_id,race_name,race_description,race_speed,race_size,dm_id ) VALUES (' + str(i+1) + ',\'' + str(data[i]['name']) + '\',NULL,' + str(data[i]['speed']) + ',\'' + str(data[i]['size']) + '\',' + dm_id + ')')
        except: 
            print("Row not added due to formatting error: {0}".format(sys.exc_info()))
        i+=1
dndFile.close()
print("Race Done")

#Skill
print("Skill Begin")
with open ("src/5e-SRD-Skills.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        try:
            ability_id = -1
            if str(data[i]['ability_score']['name']) == "STR":
                ability_id = 1
            
            if str(data[i]['ability_score']['name']) == "DEX":
                ability_id = 2
            
            if str(data[i]['ability_score']['name']) == "CON":
                ability_id = 3
            
            if str(data[i]['ability_score']['name']) == "INT":
                ability_id = 4
            
            if str(data[i]['ability_score']['name']) == "WIS":
                ability_id = 5
            
            if str(data[i]['ability_score']['name']) == "CHA":
                ability_id = 6
            
            cursor.execute('INSERT INTO skill (skill_id,skill_name,skill_description,skill_is_trained_only,ability_id) VALUES('+str(i+1)+',\''+str(data[i]['name'])+'\',\''+str(data[i]['desc'])[2:-2].replace('\'',"")+'\',False,'+str(ability_id)+')')
        except: 
            print(sys.exc_info())
        i+=1
dndFile.close()
print("Skill Done")

#Spell
print("Spell Begin")
with open ("src/5e-SRD-Spells.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        try:
            magic_id = -1
            if str(data[i]['school']['name']) == "Abjuration":
                magic_id = 1
            
            if str(data[i]['school']['name']) == "Conjuration":
                magic_id = 2
            
            if str(data[i]['school']['name']) == "Divination":
                magic_id = 3
            
            if str(data[i]['school']['name']) == "Enchantment":
                magic_id = 4
            
            if str(data[i]['school']['name']) == "Evocation":
                magic_id = 5
            
            if str(data[i]['school']['name']) == "Illusion":
                magic_id = 6
            
            if str(data[i]['school']['name']) == "Necromancy":
                magic_id = 7
            
            if str(data[i]['school']['name']) == "Transmutation":
                magic_id = 8

            material = ""
            try:
                material = str(data[i]['material'])[1:-1]
            except:
                material = ""
            cursor.execute('INSERT INTO spell (spell_id,spell_name,spell_description,spell_min_level,spell_range,spell_casting_time,spell_duration,spell_is_concentration,spell_material,magicschool_id,dm_id ) VALUES ('+str(i+1)+',\''+json.dumps(str(data[i]['name']).replace('\'',""))+'\','+json.dumps(str(data[i]['desc'][0]).replace('\'',"")) + ',' + str(data[i]['level']) + ',\'' + str(data[i]['range']) + '\',\'' + str(data[i]['casting_time']) + '\',\'' + str(data[i]['duration']) + '\',' + str(data[i]['concentration']) + ',\''+str(material).replace('\'',"") +'\',' + str(magic_id) + ',' + dm_id + ')')
        except: 
            print(sys.exc_info())
        i+=1
dndFile.close()
print("Spell Done")

#Class Level New Spells Count
print("Class Level Spells Begin")
with open ("src/5e-SRD-Levels.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        try:
            class_id = str(int(i/20))
            if class_id != "1":
                cursor.execute('INSERT INTO classlevelnewspellscount (class_id,newspellscount_class_level,newspellscount_cantrips,newspellscount_spells,newspellscount_spell_slots_level_1,newspellscount_spell_slots_level_2 ,newspellscount_spell_slots_level_3 ,newspellscount_spell_slots_level_4 ,newspellscount_spell_slots_level_5 ,newspellscount_spell_slots_level_6 ,newspellscount_spell_slots_level_7 ,newspellscount_spell_slots_level_8 ,newspellscount_spell_slots_level_9) VALUES (' + class_id + ',' + str(data[i]['level'])+',\'' + str(data[i]['spellcasting']['cantrips_known']) + '\','+ str(data[i]['spellcasting']['spells_known']) +',' + str(data[i]['spellcasting']['spell_slots_level_1']) + ',' + str(data[i]['spellcasting']['spell_slots_level_2']) + ','+ str(data[i]['spellcasting']['spell_slots_level_3']) + ','+ str(data[i]['spellcasting']['spell_slots_level_4']) + ',' + str(data[i]['spellcasting']['spell_slots_level_5']) + ','+ str(data[i]['spellcasting']['spell_slots_level_6']) + ','+str(data[i]['spellcasting']['spell_slots_level_7']) + ','+str(data[i]['spellcasting']['spell_slots_level_8']) + ','+str(data[i]['spellcasting']['spell_slots_level_9']) + ')')
        except: 
            print("HOPEFULLY YOU ARE READING THIS BECAUSE THE CODE WORKS PERFECTLY AND THIS IS A FAIL FOR NOT EXISTING WITH THE DATA :)")
        i+=1
dndFile.close()
print("Class Level Spells End")

#Race Languages
print("Race Languages Begin")
with open ("src/5e-SRD-Races.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        j = 0
        while j < len(data[i]['languages']):
            lang_id = -1
            if str(data[i]['languages'][j]['name']) == "Common":
                lang_id = 1
            
            if str(data[i]['languages'][j]['name']) == "Dwarvish":
                lang_id = 2
            
            if str(data[i]['languages'][j]['name']) == "Elvish":
                lang_id = 3
            
            if str(data[i]['languages'][j]['name']) == "Giant":
                lang_id = 4
            
            if str(data[i]['languages'][j]['name']) == "Gnomish":
                lang_id = 5
            
            if str(data[i]['languages'][j]['name']) == "Goblin":
                lang_id = 6
            
            if str(data[i]['languages'][j]['name']) == "Halfling":
                lang_id = 7
            
            if str(data[i]['languages'][j]['name']) == "Orc" or str(data[i]['languages'][j]['name']) == "Orcish":
                lang_id = 8

            if str(data[i]['languages'][j]['name']) == "Abyssal":
                lang_id = 9
            
            if str(data[i]['languages'][j]['name']) == "Celestial":
                lang_id = 10
            
            if str(data[i]['languages'][j]['name']) == "Draconic":
                lang_id = 11
            
            if str(data[i]['languages'][j]['name']) == "Deep Speech":
                lang_id = 12
            
            if str(data[i]['languages'][j]['name']) == "Infernal":
                lang_id = 13
            
            if str(data[i]['languages'][j]['name']) == "Primordial":
                lang_id = 14
            
            if str(data[i]['languages'][j]['name']) == "Sylvan":
                lang_id = 15
            
            if str(data[i]['languages'][j]['name']) == "Undercommon":
                lang_id = 16
            try:
                cursor.execute('INSERT INTO raceknownlanguage (race_id,language_id) VALUES ('+str(i+1)+','+str(lang_id) +')')
            except: 
                print("Row not added due to formatting error: {0}".format(sys.exc_info()))
            j+=1
        j = 0
        try:
            while j < len(data[i]['language_options']['from']):
                lang_id = -1
                if str(data[i]['language_options']['from'][j]['name']) == "Common":
                    lang_id = 1
                
                if str(data[i]['language_options']['from'][j]['name']) == "Dwarvish":
                    lang_id = 2
                
                if str(data[i]['language_options']['from'][j]['name']) == "Elvish":
                    lang_id = 3
                
                if str(data[i]['language_options']['from'][j]['name']) == "Giant":
                    lang_id = 4
                
                if str(data[i]['language_options']['from'][j]['name']) == "Gnomish":
                    lang_id = 5
                
                if str(data[i]['language_options']['from'][j]['name']) == "Goblin":
                    lang_id = 6
                
                if str(data[i]['language_options']['from'][j]['name']) == "Halfling":
                    lang_id = 7
                
                if str(data[i]['language_options']['from'][j]['name']) == "Orc":
                    lang_id = 8

                if str(data[i]['language_options']['from'][j]['name']) == "Abyssal":
                    lang_id = 9
                
                if str(data[i]['language_options']['from'][j]['name']) == "Celestial":
                    lang_id = 10
                
                if str(data[i]['language_options']['from'][j]['name']) == "Draconic":
                    lang_id = 11
                
                if str(data[i]['language_options']['from'][j]['name']) == "Deep Speech":
                    lang_id = 12
                
                if str(data[i]['language_options']['from'][j]['name']) == "Infernal":
                    lang_id = 13
                
                if str(data[i]['language_options']['from'][j]['name']) == "Primordial":
                    lang_id = 14
                
                if str(data[i]['language_options']['from'][j]['name']) == "Sylvan":
                    lang_id = 15
                
                if str(data[i]['language_options']['from'][j]['name']) == "Undercommon":
                    lang_id = 16
                try:
                    cursor.execute('INSERT INTO raceknownlanguage (race_id,language_id) VALUES ('+str(i+1)+','+str(lang_id) +')')
                except: 
                    print("Row not added due to formatting error: {0}".format(sys.exc_info()))
                j+=1
        except:
            print("No language option")    
        i+=1
dndFile.close()
print("Race Languages End")

#Class Learnable Spell
print("Class Learnable Spells Begin")
with open ("src/5e-SRD-Spells.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        j = 0
        while j < len(data[i]['classes']):
            class_id = -1
            if str(data[i]['classes'][j]['name']) == "Barbarian":
                class_id = 1
            
            if str(data[i]['classes'][j]['name']) == "Bard":
                class_id = 2
            
            if str(data[i]['classes'][j]['name']) == "Cleric":
                class_id = 3
            
            if str(data[i]['classes'][j]['name']) == "Druid":
                class_id = 4
            
            if str(data[i]['classes'][j]['name']) == "Fighter":
                class_id = 5
            
            if str(data[i]['classes'][j]['name']) == "Monk":
                class_id = 6

            if str(data[i]['classes'][j]['name']) == "Paladin":
                class_id = 7
            
            if str(data[i]['classes'][j]['name']) == "Ranger":
                class_id = 8
            
            if str(data[i]['classes'][j]['name']) == "Rogue":
                class_id = 9
            
            if str(data[i]['classes'][j]['name']) == "Sorcerer":
                class_id = 10
            
            if str(data[i]['classes'][j]['name']) == "Warlock":
                class_id = 11
            
            if str(data[i]['classes'][j]['name']) == "Wizard":
                class_id = 12
            
            try:
                cursor.execute('INSERT INTO classlearnablespell (spell_id,class_id,cls_required_class_level) VALUES (' + str(i+1) + ',' + str(class_id) +','+ str(data[i]['level']) +')')
            except: 
                print("Row not added due to formatting error: {0}".format(sys.exc_info()))
            j+=1
        i+=1
dndFile.close()
print("Class Learnable Spells End")

#Monster Ability Score
print("Monster Ability Score Begin")
with open ("src/5e-SRD-Monsters.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        try:
            cursor.execute('INSERT INTO monsterabilityscore (monster_id,ability_id,monsterabilityscore_value) VALUES (' + str(i+1) + ',1,'+ str(data[i]['strength']) +')')
            cursor.execute('INSERT INTO monsterabilityscore (monster_id,ability_id,monsterabilityscore_value) VALUES (' + str(i+1) + ',2,'+ str(data[i]['dexterity']) +')')
            cursor.execute('INSERT INTO monsterabilityscore (monster_id,ability_id,monsterabilityscore_value) VALUES (' + str(i+1) + ',3,'+ str(data[i]['constitution']) +')')
            cursor.execute('INSERT INTO monsterabilityscore (monster_id,ability_id,monsterabilityscore_value) VALUES (' + str(i+1) + ',4,'+ str(data[i]['intelligence']) +')')
            cursor.execute('INSERT INTO monsterabilityscore (monster_id,ability_id,monsterabilityscore_value) VALUES (' + str(i+1) + ',5,'+ str(data[i]['wisdom']) +')')
            cursor.execute('INSERT INTO monsterabilityscore (monster_id,ability_id,monsterabilityscore_value) VALUES (' + str(i+1) + ',6,'+ str(data[i]['charisma']) +')')
        except: 
            print("Row not added due to formatting error: {0}".format(sys.exc_info()))
        i+=1
dndFile.close()
print("Monster Ability Score End")


#Race Ability Score Modifier
print("Race Ability Score Modifier Begin")
with open ("src/5e-SRD-Races.json", 'r',encoding='utf-8') as dndFile:
    data = json.load(dndFile)
    i = 0
    while i < len(data):
        j = 0
        while j < len(data[i]['ability_bonuses']):
            ability_id = -1
            
            if str(data[i]['ability_bonuses'][j]['name']) == "STR":
                ability_id = 1
            
            if str(data[i]['ability_bonuses'][j]['name']) == "DEX":
                ability_id = 2
            
            if str(data[i]['ability_bonuses'][j]['name']) == "CON":
                ability_id = 3
            
            if str(data[i]['ability_bonuses'][j]['name']) == "INT":
                ability_id = 4
            
            if str(data[i]['ability_bonuses'][j]['name']) == "WIS":
                ability_id = 5
            
            if str(data[i]['ability_bonuses'][j]['name']) == "CHA":
                ability_id = 6
            try:
                cursor.execute('INSERT INTO raceabilityscoremodifier (race_id,ability_id,racemodifier_value) VALUES (' + str(i+1) + ','+ str(ability_id)+','+ str(data[i]['ability_bonuses'][j]['bonus']) +')')
            except: 
                print(sys.exc_info())
            j+=1
        i+=1
dndFile.close()
print("Race Ability Score Modifier End")

mydb.commit()
cursor.close()
print ("Done")