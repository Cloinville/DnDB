use csuciklo_dndb;

DROP VIEW IF EXISTS campaign_players;
CREATE VIEW campaign_players 
AS
SELECT player.player_id,
	   player.player_username,
	   `character`.char_id,
       `character`.char_name,
       adventuringparty.party_id,
       adventuringparty.party_name,
       campaign.campaign_id,
       campaign.campaign_name,
       dungeonmaster.dm_id
FROM player JOIN `character` USING(player_id)
			JOIN adventuringparty USING(party_id)
            JOIN campaign USING(party_id)
            JOIN dungeonmaster USING(dm_id);

# TODO: remove this, once have implemented Flask-side replacement w/get_previews()
DROP PROCEDURE IF EXISTS get_campaign_previews;
DELIMITER $$
CREATE PROCEDURE get_campaign_previews(IN in_username VARCHAR(32))
BEGIN
	SELECT campaign_id,
		   campaign_name, 
		   party_name
    FROM campaign_players
    WHERE player_username = in_username;
END $$
DELIMITER ;

# Create a view for each of the associated entities
DROP VIEW IF EXISTS character_abilities;
CREATE VIEW character_abilities
AS
SELECT *
FROM characterabilityscore JOIN ability USING(ability_id);

DROP VIEW IF EXISTS race_vulnerabilities;
CREATE VIEW race_vulnerabilities
AS
SELECT *
FROM vulnerability JOIN damagetype USING(damage_type_id);

DROP VIEW IF EXISTS race_resistances;
CREATE VIEW race_resistances
AS
SELECT *
FROM resistance JOIN damagetype USING(damage_type_id);

DROP VIEW IF EXISTS class_spells;
CREATE VIEW class_spells
AS
SELECT *
FROM classlearnablespell JOIN spell USING(spell_id);

DROP VIEW IF EXISTS spell_components;
CREATE VIEW spell_components
AS
SELECT *
FROM spellcomponent JOIN item USING(item_id);

DROP VIEW IF EXISTS monster_abilities;
CREATE VIEW monster_abilities
AS
SELECT *
FROM monsterabilityscore JOIN ability USING(ability_id);

DROP VIEW IF EXISTS race_ability_modifiers;
CREATE VIEW race_ability_modifiers
AS
SELECT *
FROM raceabilityscoremodifier JOIN ability USING(ability_id);

DROP TRIGGER IF EXISTS default_player_nickname;
DELIMITER $$
CREATE TRIGGER default_player_nickname
BEFORE
INSERT ON player
FOR EACH ROW
BEGIN
	IF NEW.player_nickname = ""
    THEN
		SET NEW.player_nickname = NEW.player_username;
	END IF;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_non_foreign_key_column_names_and_datatypes;
DELIMITER $$
CREATE PROCEDURE get_non_foreign_key_column_names_and_datatypes(IN entity VARCHAR(255))
BEGIN
	SELECT column_name, column_type
	FROM INFORMATION_SCHEMA.columns
	WHERE table_schema="csuciklo_dndb"
		  AND table_name = entity
		  AND column_key != "MUL";
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_foreign_key_column_names_and_referenced_table_names;
DELIMITER $$
CREATE PROCEDURE get_foreign_key_column_names_and_referenced_table_names(IN entity VARCHAR(255))
BEGIN
	SELECT COLUMN_NAME, REFERENCED_TABLE_NAME
	FROM INFORMATION_SCHEMA.key_column_usage
	WHERE table_schema="csuciklo_dndb" 
		  AND table_name = entity
          AND REFERENCED_TABLE_NAME IS NOT NULL;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_display_name;
DELIMITER $$
CREATE FUNCTION get_display_name(in_table_name VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	DECLARE display_name VARCHAR(255) DEFAULT "";
    DECLARE display_name_prefix VARCHAR(255);
    DECLARE display_name_suffix VARCHAR(255) DEFAULT "_name";
    
    IF in_table_name = "player" THEN SET display_name_suffix = "_nickname";
    END IF;
    
    IF in_table_name = "character" THEN SET display_name_prefix = "char";
    ELSEIF in_table_name = "damagetype" THEN SET display_name_prefix = "damage_type";
    ELSEIF in_table_name = "schoolofmagic" THEN SET display_name_prefix = "magicschool";
    ELSE SET display_name_prefix = in_table_name;
    END IF;
    
    RETURN CONCAT(display_name_prefix, display_name_suffix);
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_display_and_column_names;
DELIMITER $$
CREATE FUNCTION get_display_and_column_names(in_table_name VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	DECLARE display_name VARCHAR(255) DEFAULT "";
    DECLARE display_name_prefix VARCHAR(255);
    DECLARE display_name_suffix VARCHAR(255) DEFAULT "_name";
    
    IF in_table_name = "player" THEN SET display_name_suffix = "_nickname";
    END IF;
    
    IF in_table_name = "character" THEN SET display_name_prefix = "char";
    ELSEIF in_table_name = "damagetype" THEN SET display_name_prefix = "damage_type";
    ELSEIF in_table_name = "schoolofmagic" THEN SET display_name_prefix = "magicschool";
    ELSE SET display_name_prefix = in_table_name;
    END IF;
    
    SET display_name = CONCAT(display_name_prefix, display_name_suffix);
    RETURN CONCAT(display_name, ", '", display_name, "'");
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_table_name_from_primary_key_name;
DELIMITER $$
CREATE FUNCTION get_table_name_from_primary_key_name(primary_key_name VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	DECLARE primary_key_prefix VARCHAR(255) DEFAULT "";
    SET primary_key_prefix = SUBSTRING_INDEX(primary_key_name, "_id", 1);
    
    IF primary_key_prefix = "damage_type" THEN SET primary_key_prefix = "damagetype";
    ELSEIF primary_key_prefix = "magicschool" THEN SET primary_key_prefix = "schoolofmagic";
    ELSEIF primary_key_prefix = "dm" THEN SET primary_key_prefix = "dungeonmaster";
    ELSEIF primary_key_prefix = "char" THEN SET primary_key_prefix = "character";
    ELSEIF primary_key_prefix = "encounter" THEN SET primary_key_prefix = "monsterencounter";
    END IF;
    
    RETURN primary_key_prefix;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_display_name_select_statement;
DELIMITER $$
CREATE FUNCTION get_display_name_select_statement(in_table_name VARCHAR(255))
RETURNS TEXT
DETERMINISTIC
BEGIN
	DECLARE select_statement TEXT DEFAULT "";
    IF in_table_name = "dungeonmaster" THEN 
		SET select_statement = "SELECT player_nickname FROM dungeonmaster JOIN player USING(player_id)";
    ELSEIF in_table_name = "monsterencounter" THEN SET select_statement = "SELECT monster_name FROM monster JOIN monsterencounter USING(monster_id)";
    ELSEIF in_table_name = "weapon" THEN SET select_statement = "SELECT item_name FROM weapon JOIN item USING(item_id)";
    ELSE SET select_statement = CONCAT("SELECT ", get_display_name(in_table_name), " FROM ", in_table_name);
    END IF;
    
    RETURN select_statement;
END $$
DELIMITER ;

# SHOULD BE OBSELETE NOW - IF IS, CAN DELETE
DROP FUNCTION IF EXISTS get_display_and_col_names_select_statement;
DELIMITER $$
CREATE FUNCTION get_display_and_col_names_select_statement(in_table_name VARCHAR(255))
RETURNS TEXT
DETERMINISTIC
BEGIN
	DECLARE select_statement TEXT DEFAULT "";
    IF in_table_name = "dungeonmaster" THEN 
		SET select_statement = "SELECT player_nickname, 'player_nickname' FROM dungeonmaster JOIN player USING(player_id)";
    ELSEIF in_table_name = "monsterencounter" THEN SET select_statement = "SELECT monster_name, 'monster_name' FROM monster JOIN monsterencounter USING(monster_id)";
    ELSEIF in_table_name = "weapon" THEN SET select_statement = "SELECT item_name, 'item_name' FROM weapon JOIN item USING(item_id)";
    ELSE SET select_statement = CONCAT("SELECT ", get_display_and_column_names(in_table_name), " FROM ", in_table_name);
    END IF;
    
    RETURN select_statement;
END $$
DELIMITER ;

-- # TODO: 4/28: Finish updating for adding fk val and colnames to select
-- DROP FUNCTION IF EXISTS get_select_stmt_for_displayname_displaycol_fk_fkcol;
-- DELIMITER $$
-- CREATE FUNCTION get_select_stmt_for_displayname_displaycol_fk_fkcol(in_table_name VARCHAR(255))
-- RETURNS TEXT
-- DETERMINISTIC
-- BEGIN
-- 	DECLARE select_statement TEXT DEFAULT "";
--     IF in_table_name = "dungeonmaster" 
--     THEN
-- 		SET select_statement = "SELECT CONCAT(player_nickname, ' ( ', player_username, ' ) '), 'player_nickname', dm_id, 'dm_id' FROM dungeonmaster JOIN player USING(player_id)";  
--     # CONCAT(player_nickname, "(", player_username, ")"), 'player_nickname' FROM dungeonmaster JOIN player USING(player_id)
-- 		#SET select_statement = CONCAT("SELECT CONCAT(player_nickname,", ' ( ', "player_username", ' ) ', "'player_nickname', dm_id, 'dm_id' FROM dungeonmaster JOIN player USING(player_id)");
--     ELSEIF in_table_name = "monsterencounter" THEN SET select_statement = "SELECT monster_name, 'monster_name', monster_id, 'monster_id' FROM monster JOIN monsterencounter USING(monster_id)";
--     ELSEIF in_table_name = "weapon" THEN SET select_statement = "SELECT item_name, 'item_name', item_id, 'item_id' FROM weapon JOIN item USING(item_id)";
--     ELSE SET select_statement = CONCAT("SELECT ", get_comma_separated_displayname_displaycolname_fkvalue_fkcolname(in_table_name), " FROM ", in_table_name);
--     END IF;
--     
--     RETURN select_statement;
-- END $$
-- DELIMITER ;

DROP PROCEDURE IF EXISTS get_all_column_names;
DELIMITER $$
CREATE PROCEDURE get_all_column_names(in_table_name VARCHAR(255))
BEGIN
	SELECT column_name
	FROM INFORMATION_SCHEMA.columns
	WHERE table_schema="csuciklo_dndb"
		  AND table_name = in_table_name;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS player_is_dm;
DELIMITER $$
CREATE FUNCTION player_is_dm(in_username VARCHAR(255))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
	RETURN get_dm_id_for_player(in_username) IS NOT NULL;
# TODO
	# RETURN in_username IN (SELECT player_username FROM dungeonmaster JOIN player USING(player_id) WHERE player_username = in_username);
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_dm_id_for_player;
DELIMITER $$
CREATE FUNCTION get_dm_id_for_player(in_username VARCHAR(255))
RETURNS INT(10)
DETERMINISTIC
BEGIN
	RETURN (SELECT dm_id FROM dungeonmaster JOIN player USING(player_id) WHERE player_username = in_username LIMIT 1);
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_player_id_from_username;
DELIMITER $$
CREATE FUNCTION get_player_id_from_username(in_username VARCHAR(255))
RETURNS INT(10)
DETERMINISTIC
BEGIN
	RETURN (SELECT player_id FROM player WHERE player_username = in_username LIMIT 1);
END $$
DELIMITER ;

-- DROP VIEW IF EXISTS campaign_previews;
-- CREATE VIEW campaign_previews
-- AS
-- SELECT "campaign_id" as "identifier",
-- 	   campaign_id as "campaign_id", 
-- 	   campaign_name as "Campaign Name", 
--        party_name as "Adventuring Party", 
--        player_username as "DM"
-- FROM campaign JOIN adventuringparty USING(party_id) 
-- 			  JOIN dungeonmaster USING(dm_id) 
--               JOIN player USING(player_id);
--               
-- DROP VIEW IF EXISTS character_previews;
-- CREATE VIEW character_previews
-- AS
-- SELECT "char_id" as "identifier",
-- 	   char_id as "char_id", 
-- 	   char_name as "Name", 
--        race_name as "Race",
--        char_public_class as "Class",
--        player_username as "Played By"
-- FROM `character` JOIN player USING(player_id) 
-- 			     JOIN race USING(race_id);
--                  
-- DROP VIEW IF EXISTS monster_previews;
-- CREATE VIEW monster_previews
-- AS
-- SELECT "monster_id" as "identifier",
-- 	   monster_id as "monster_id", 
-- 	   monster_name as "Name", 
--        monster_type as "Type",
--        monster_challenge_rating as "Challenge Rating",
--        monster_base_hp as "Base HP"
-- FROM monster;

-- DROP VIEW IF EXISTS spell_previews;
-- CREATE VIEW spell_previews
-- AS
-- SELECT 'spell_id' as 'identifier',
-- 	   spell_id as 'spell_id', 
-- 	   spell_name as 'Name', 
--        magicschool_name as 'School of Magic',
--        spell_min_level as 'Spell Level'
-- FROM spell JOIN schoolofmagic USING(magicschool_id);

-- DROP VIEW IF EXISTS item_previews;
-- CREATE VIEW item_previews
-- AS
-- SELECT 'item.item_id' as 'identifier',
-- 	   item.item_id as 'item.item_id', 
-- 	   item_name as 'Name', 
--        item_rarity as 'Rarity',
--        item_type as 'Type'
-- FROM item LEFT JOIN weapon USING(item_id)
-- UNION
-- SELECT 'item_id' as 'identifier',
-- 	   item_id as 'item_id', 
-- 	   item_name as 'Name', 
--        item_rarity as 'Rarity',
--        item_type as 'Type'
-- FROM weapon LEFT JOIN item USING(item_id);

-- DROP VIEW IF EXISTS class_previews;
-- CREATE VIEW class_previews
-- AS
-- SELECT 'class_id' as 'identifier',
-- 	   class_id as 'class_id', 
-- 	   class_name as 'Name', 
--        class_role as 'Role'
-- FROM class;

-- DROP VIEW IF EXISTS race_previews;
-- CREATE VIEW race_previews
-- AS
-- SELECT 'race_id' as 'identifier',
-- 	   race_id as 'race_id', 
-- 	   race_name as 'Name',
--        race_size as 'Size',
--        race_speed as 'Speed'
-- FROM race;

# This is still used - get_previews uses this to get which columns to return
DROP FUNCTION IF EXISTS get_select_for_entity_previews;
DELIMITER $$
CREATE FUNCTION get_select_for_entity_previews(entity VARCHAR(255))
RETURNS TEXT
DETERMINISTIC
BEGIN
	DECLARE select_stmt TEXT DEFAULT "";
    
	IF entity = "character"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'char_id' as 'char_id', 'Name' as 'Name', 'Race' as 'Race', 'Class' as 'Class', 'Played By' as 'Played By' UNION SELECT 'char_id' as 'identifier', 'character' as 'entity', char_id as 'char_id', char_name as 'Name', race_name as 'Race', char_public_class as 'Class', player_username as 'Played By' FROM `character` JOIN player USING(player_id) JOIN race USING(race_id)";
	ELSEIF entity = "monster"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'monster_id' as 'monster_id', 'Name' as 'Name', 'Type' as 'Type', 'Challenge Rating' as 'Challenge Rating', 'Base HP' as 'Base HP' UNION SELECT 'monster_id' as 'identifier', 'monster' as 'entity', monster_id as 'monster_id', monster_name as 'Name', monster_type as 'Type', monster_challenge_rating as 'Challenge Rating', monster_base_hp as 'Base HP' FROM monster";
	ELSEIF entity = "campaign"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'campaign_id' as 'campaign_id', 'DM' as 'DM', 'Campaign Name' as 'Campaign Name', 'Adventuring Party' as 'Adventuring Party' UNION SELECT 'campaign_id' as 'identifier', 'campaign' as 'entity', campaign_id as 'campaign_id', player_nickname as 'DM', campaign_name as 'Campaign Name', party_name as 'Adventuring Party' FROM campaign JOIN dungeonmaster USING(dm_id) JOIN player USING(player_id) JOIN adventuringparty USING(party_id)";
    ELSEIF entity = "spell"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'spell_id' as 'spell_id', 'Name' as 'Name', 'School of Magic' as 'School of Magic', 'Spell Level' as 'Spell Level' UNION SELECT 'spell_id' as 'identifier', 'spell' as 'entity', spell_id as 'spell_id', spell_name as 'Name', magicschool_name as 'School of Magic', spell_min_level as 'Spell Level' FROM spell LEFT JOIN schoolofmagic USING(magicschool_id)";
	ELSEIF entity = "item"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'item.item_id' as 'item.item_id', 'Name' as 'Name', 'Rarity' as 'Rarity', 'Type' as 'Type' UNION SELECT 'item.item_id' as 'identifier', 'item' as 'entity', item.item_id as 'item.item_id', item_name as 'Name', item_rarity as 'Rarity', item_type as 'Type' FROM item LEFT JOIN weapon USING(item_id) UNION SELECT 'item.item_id' as 'identifier', 'item' as 'entity', item.item_id as 'item.item_id', item_name as 'Name', item_rarity as 'Rarity', item_type as 'Type' FROM weapon LEFT JOIN item USING(item_id)";
	ELSEIF  entity = "weapon"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'item_id' as 'item_id', 'Name' as 'Name', 'Rarity' as 'Rarity', 'Type' as 'Type' UNION SELECT 'item_id' as 'identifier', 'weapon' as 'entity', item_id as 'item_id', item_name as 'Name', item_rarity as 'Rarity', item_type as 'Type' FROM weapon LEFT JOIN item USING(item_id)";
    ELSEIF entity = "class"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'class_id' as 'class_id', 'Name' as 'Name', 'Role' as 'Role' UNION SELECT 'class_id' as 'identifier', 'class' as 'entity', class_id as 'class_id', class_name as 'Name', class_role as 'Role' FROM class";
	ELSEIF entity = "race"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'race_id' as 'race_id', 'Name' as 'Name', 'Size' as 'Size', 'Speed' as 'Speed' UNION SELECT 'race_id' as 'identifier', 'race' as 'entity', race_id as 'race_id', race_name as 'Name', race_size as 'Size', race_speed as 'Speed' FROM race";
    ELSEIF entity = "monsterparty"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'monsterparty_id' as 'monsterparty_id', 'Location' as 'Location', 'Hoard Size' as 'Hoard Size', 'Average Challenge Rating' as 'Average Challenge Rating' from monsterparty JOIN monsterencounter USING(monsterparty_id) JOIN monster USING(monster_id) UNION SELECT 'monsterparty_id' as 'identifier', 'monsterparty' as 'entity', monsterparty_id, monsterparty_location as 'Location', hoard_size as 'Hoard Size', avg_cr as 'Average Challenge Rating' FROM ( SELECT monsterparty_id as 'monsterparty_id', monsterparty_location, count(*) as hoard_size, avg(monster_challenge_rating) as avg_cr, monsterparty.dm_id as dm_id from monsterparty JOIN monsterencounter USING(monsterparty_id) JOIN monster USING(monster_id) GROUP BY monsterparty_id ) as monsterparty_values";
	ELSE
		SET select_stmt = CONCAT("SELECT * FROM ", entity);
	END IF;
    
    RETURN select_stmt;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_primary_key_name_from_table_name;
DELIMITER $$
CREATE FUNCTION get_primary_key_name_from_table_name(in_table_name VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	DECLARE primary_key_name VARCHAR(255) DEFAULT "";
    
	SELECT column_name 
    INTO primary_key_name
    FROM INFORMATION_SCHEMA.columns 
    WHERE table_schema="csuciklo_dndb" 
		  AND table_name = in_table_name 
          AND column_key = "PRI";
          
	RETURN primary_key_name;
END $$
DELIMITER ;

-- DROP FUNCTION IF EXISTS get_preview_from_condition;
-- DELIMITER $$
-- CREATE FUNCTION get_preview_from_condition(entity VARCHAR(255), in_condition TEXT)
-- RETURNS VARCHAR(255)
-- DETERMINISTIC
-- BEGIN
-- 	DECLARE result VARCHAR(255) DEFAULT "";
--     DECLARE full_query TEXT DEFAULT "";
--     DECLARE stmt TEXT DEFAULT "";
--     DECLARE colname VARCHAR(255) DEFAULT "";
--     
-- 	SELECT get_primary_key_name_from_table_name(entity) into colname;
-- 	SET full_query = CONCAT("SELECT ", @colname, " INTO ", result, " FROM ", entity, " ", in_condition);
-- 	EXECUTE full_query;
--     
--     RETURN result;
-- END $$
-- DELIMITER ;

DROP PROCEDURE IF EXISTS get_primary_key_values_from_condition;
DELIMITER $$
CREATE PROCEDURE get_primary_key_values_from_condition(entity VARCHAR(255), in_condition TEXT)
BEGIN    
	SELECT get_primary_key_name_from_table_name(entity) into @colname;
	SET @query = CONCAT("SELECT ", @colname, " FROM ", entity, " ", in_condition);
    PREPARE stmt FROM @query;
    EXECUTE stmt;
END $$
DELIMITER ;

# IS USED
DROP PROCEDURE IF EXISTS get_previews;
DELIMITER $$
CREATE PROCEDURE get_previews(entity VARCHAR(255), in_condition TEXT)
BEGIN
    SET @select = get_select_for_entity_previews(entity);
    SET @condition = in_condition;
    SET @query = CONCAT(@select, " ", @condition);
    PREPARE stmt FROM @query;
    EXECUTE stmt;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_comma_separated_displayname_displaycolname_fkvalue_fkcolname;
DELIMITER $$
CREATE FUNCTION get_comma_separated_displayname_displaycolname_fkvalue_fkcolname(in_table_name VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	DECLARE display_name VARCHAR(255) DEFAULT "";
    DECLARE display_name_prefix VARCHAR(255);
    DECLARE display_name_suffix VARCHAR(255) DEFAULT "_name";
    DECLARE fk_name VARCHAR(255) DEFAULT "";
    SELECT get_primary_key_name_from_table_name(in_table_name) INTO fk_name;
    
    IF in_table_name = "player" THEN SET display_name_suffix = "_nickname";
    END IF;
    
    IF in_table_name = "character" THEN SET display_name_prefix = "char";
    ELSEIF in_table_name = "damagetype" THEN SET display_name_prefix = "damage_type";
    ELSEIF in_table_name = "schoolofmagic" THEN SET display_name_prefix = "magicschool";
    ELSE SET display_name_prefix = in_table_name;
    END IF;
    
    SET display_name = CONCAT(display_name_prefix, display_name_suffix);
    RETURN CONCAT(display_name, ", '", display_name, "', ", fk_name, ", '", fk_name, "'");
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_displayname_displaycolname_fkvalue_fkcolname;
DELIMITER $$
CREATE PROCEDURE get_displayname_displaycolname_fkvalue_fkcolname(entity VARCHAR(255))
BEGIN
    IF entity = "dungeonmaster" 
    THEN
		SELECT CONCAT(player_nickname, ' ( ', player_username, ' ) '), "CONCAT(player_nickname, ' ( ', player_username, ' ) ')", dm_id, 'dm_id' FROM dungeonmaster JOIN player USING(player_id); 
	ELSE
		IF entity = "monsterencounter" 
        THEN 
			SET @query = "SELECT monster_name, 'monster_name', monster_id, 'monster_id' FROM monster JOIN monsterencounter USING(monster_id)";
		ELSEIF entity = "weapon" 
        THEN 
			SET @query = "SELECT item_name, 'item_name', item_id, 'item_id' FROM weapon JOIN item USING(item_id)";
		ELSE 
			SET @query = CONCAT("SELECT ", get_comma_separated_displayname_displaycolname_fkvalue_fkcolname(entity), " FROM ", entity);
		END IF;

		PREPARE stmt FROM @query;
		EXECUTE stmt;
	END IF;
END $$
DELIMITER ;

# TODO: Probably just drop this
DROP PROCEDURE IF EXISTS get_created_records_for_entity;
DELIMITER $$
CREATE PROCEDURE get_created_records_for_entity(in_player_username VARCHAR(255), entity VARCHAR(255))
BEGIN
    DECLARE in_dm_id INT(10);
    DECLARE entity_id_name VARCHAR(255);
    
    IF entity = 'character'
    THEN
		#TODO: try to find out if can find way to return all associated as well
		SELECT * FROM `character` WHERE player_id = ( SELECT player_id FROM player WHERE player_username = in_player_username);
	ELSE
		SELECT get_dm_id_for_player(in_player_username) INTO in_dm_id;
        IF in_dm_id IS NOT NULL
        THEN
			SET @query = CONCAT("SELECT * FROM ", entity, " WHERE dm_id = ", in_dm_id);
		ELSE
			SET entity_id_name = get_primary_key_name_from_table_name(entity);
			SET @query = CONCAT("SELECT * FROM ", entity, " WHERE ", entity_id_name, " = 1 AND ", entity_id_name, " != 1");
		END IF;
        PREPARE stmt FROM @query;
        EXECUTE stmt;
	END IF;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_previews_for_entity_created_by_player;
DELIMITER $$
CREATE PROCEDURE get_previews_for_entity_created_by_player(in_username VARCHAR(255), in_entity VARCHAR(255))
BEGIN
	DECLARE in_dm_id INT(10);
    DECLARE entity_id_name VARCHAR(255);
    DECLARE search_condition TEXT DEFAULT "";
    
    IF in_entity = 'character'
    THEN
		#TODO: try to find out if can find way to return all associated as well
		# SELECT * FROM `character` WHERE player_id = ( SELECT player_id FROM player WHERE player_username = in_player_username);
        CALL get_previews("character", CONCAT("WHERE player_id = ( SELECT player_id FROM player WHERE player_username = '", in_username, "')"));
	ELSE
		SELECT get_dm_id_for_player(in_username) INTO in_dm_id;
        IF in_dm_id IS NOT NULL
        THEN
			SET search_condition = CONCAT("WHERE dm_id = ", in_dm_id);
		ELSE
			SET entity_id_name = get_primary_key_name_from_table_name(in_entity);
			SET search_condition = CONCAT("WHERE ", entity_id_name, " = 1 AND ", entity_id_name, " != 1");
		END IF;
        CALL get_previews(in_entity, search_condition);
	END IF;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS update_field_in_table;
DELIMITER $$
CREATE PROCEDURE update_field_in_table(in_table VARCHAR(255), in_field VARCHAR(255), new_value VARCHAR(255), in_condition TEXT)
BEGIN
	DECLARE formatted_in_table VARCHAR(255) DEFAULT "";
    IF in_table = "character"
    THEN
		SET formatted_in_table = "`character`";
	ELSE
		SET formatted_in_table = in_table;
	END IF;
	SET @query = CONCAT("UPDATE ", formatted_in_table, " SET ", in_field, " = ", "'", new_value, "' ", in_condition);
	PREPARE stmt FROM @query;
	EXECUTE stmt;
END $$
DELIMITER ;