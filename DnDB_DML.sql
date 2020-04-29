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
	RETURN in_username IN (SELECT player_username FROM dungeonmaster JOIN player USING(player_id) WHERE player_username = in_username);
END $$
DELIMITER ;

DROP VIEW IF EXISTS campaign_previews;
CREATE VIEW campaign_previews
AS
SELECT "campaign_id" as "identifier",
	   campaign_id as "campaign_id", 
	   campaign_name as "Campaign Name", 
       party_name as "Adventuring Party", 
       player_username as "DM"
FROM campaign JOIN adventuringparty USING(party_id) 
			  JOIN dungeonmaster USING(dm_id) 
              JOIN player USING(player_id);
              
DROP VIEW IF EXISTS character_previews;
CREATE VIEW character_previews
AS
SELECT "char_id" as "identifier",
	   char_id as "char_id", 
	   char_name as "Name", 
       race_name as "Race",
       char_public_class as "Class",
       player_username as "Played By"
FROM `character` JOIN player USING(player_id) 
			     JOIN race USING(race_id);
                 
DROP VIEW IF EXISTS monster_previews;
CREATE VIEW monster_previews
AS
SELECT "monster_id" as "identifier",
	   monster_id as "monster_id", 
	   monster_name as "Name", 
       monster_type as "Type",
       monster_challenge_rating as "Challenge Rating",
       monster_base_hp as "Base HP"
FROM monster;

DROP VIEW IF EXISTS spell_previews;
CREATE VIEW spell_previews
AS
SELECT 'spell_id' as 'identifier',
	   spell_id as 'spell_id', 
	   spell_name as 'Name', 
       magicschool_name as 'School of Magic',
       spell_min_level as 'Spell Level'
FROM spell JOIN schoolofmagic USING(magicschool_id);

DROP VIEW IF EXISTS item_previews;
CREATE VIEW item_previews
AS
SELECT 'item.item_id' as 'identifier',
	   item.item_id as 'item.item_id', 
	   item_name as 'Name', 
       item_rarity as 'Rarity',
       item_type as 'Type'
FROM item LEFT JOIN weapon USING(item_id)
UNION
SELECT 'item_id' as 'identifier',
	   item_id as 'item_id', 
	   item_name as 'Name', 
       item_rarity as 'Rarity',
       item_type as 'Type'
FROM weapon LEFT JOIN item USING(item_id);

DROP VIEW IF EXISTS class_previews;
CREATE VIEW class_previews
AS
SELECT 'class_id' as 'identifier',
	   class_id as 'class_id', 
	   class_name as 'Name', 
       class_role as 'Role'
FROM class;

DROP VIEW IF EXISTS race_previews;
CREATE VIEW race_previews
AS
SELECT 'race_id' as 'identifier',
	   race_id as 'race_id', 
	   race_name as 'Name',
       race_size as 'Size',
       race_speed as 'Speed'
FROM race;

# WE USE THIS
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

-- DROP PROCEDURE IF EXISTS get_previews_col_names;
-- DELIMITER $$
-- CREATE PROCEDURE get_previews_col_names(entity VARCHAR(255))
-- BEGIN
-- 	DECLARE select_stmt VARCHAR(255) DEFAULT "";
-- 	IF entity = "character"
--     THEN
-- 		SET select_stmt = "SELECT 'char_id' as 'identifier', 'char_id' as 'char_id', 'char_name' as 'Name', 'race_name' as 'Race', 'char_public_class' as 'Class', 'player_username' as 'Played By'";
-- 	ELSEIF entity = "monster"
--     THEN
-- 		SET select_stmt = "SELECT 'monster_id' as 'identifier', monster_id as 'monster_id', monster_name as 'Name', monster_type as 'Type', monster_challenge_rating as 'Challenge Rating', monster_base_hp as 'Base HP' FROM monster";
-- 	ELSEIF entity = "campaign"
--     THEN
-- 		SET select_stmt = "SELECT 'campaign_id' as 'identifier', campaign_id as 'campaign_id', player_nickname as 'DM', campaign_name as 'Campaign Name', party_name as 'Adventuring Party' FROM campaign JOIN dungeonmaster USING(dm_id) JOIN player USING(player_id) JOIN adventuringparty USING(party_id)";
--     ELSEIF entity = "spell"
--     THEN
-- 		SET select_stmt = "SELECT 'spell_id' as 'identifier', spell_id as 'spell_id', spell_name as 'Name', magicschool_name as 'School of Magic', spell_min_level as 'Spell Level' FROM spell LEFT JOIN schoolofmagic USING(magicschool_id)";
-- 	ELSEIF entity = "item"
--     THEN
-- 		SET select_stmt = "SELECT 'item.item_id' as 'identifier', item.item_id as 'item.item_id', item_name as 'Name', item_rarity as 'Rarity', item_type as 'Type' FROM item LEFT JOIN weapon USING(item_id) UNION SELECT 'item.item_id' as 'identifier', item.item_id as 'item.item_id', item_name as 'Name', item_rarity as 'Rarity', item_type as 'Type' FROM weapon LEFT JOIN item USING(item_id)";
-- 	ELSEIF  entity = "weapon"
--     THEN
-- 		SET select_stmt = "SELECT 'item_id' as 'identifier', item_id as 'item_id', item_name as 'Name', item_rarity as 'Rarity', item_type as 'Type' FROM weapon LEFT JOIN item USING(item_id)";
--     ELSEIF entity = "class"
--     THEN
-- 		SET select_stmt = "SELECT 'class_id' as 'identifier', class_id as 'class_id', class_name as 'Name', class_role as 'Role' FROM class";
-- 	ELSEIF entity = "race"
--     THEN
-- 		SET select_stmt = "SELECT 'race_id' as 'identifier', race_id as 'race_id', race_name as 'Name', race_size as 'Size', race_speed as 'Speed' FROM race";
--     ELSE
-- 		SET select_stmt = CONCAT("SELECT * FROM ", entity);
-- 	END IF;
-- END
-- DELIMITER ;

-- CREATE VIEW creations
-- AS
-- SELECT * FROM player JOIN `character` USING(player_id)
-- 					 JOIN 

# TODO: INSERT ON monster: IF NEW.monster_name IS NULL THEN SET NEW.monster_name = race_name of linked race
-- DROP VIEW IF EXISTS full_race_details;
-- CREATE VIEW full_race_details
-- AS
-- SELECT *
-- FROM race JOIN raceabilityscoremodifier USING(race_id)
-- 		  JOIN ability USING(ability_id)
--           JOIN raceknownlanguage USING(race_id)
--           JOIN `language` USING(language_id)
--           JOIN resistance USING(race_id)
--           JOIN vulnerability USING(race_id)
--           JOIN damagetype USING(damage_type_id);
          

-- DROP VIEW IF EXISTS full_character_details;
-- CREATE VIEW full_character_details
-- AS
-- SELECT *
-- FROM `character` JOIN characterabilityscore USING(char_id)
-- 				 JOIN ability USING(ability_id)
--                  JOIN race USING(race_id)
--                  JOIN 

-- # TODO: finish, using views that combine associated entity info
-- DROP VIEW IF EXISTS player_creations;
-- CREATE VIEW player_creations 
-- AS
-- SELECT *
-- FROM player JOIN `character` USING(player_id)
-- 			JOIN dungeonmaster USING(dm_id)
--             JOIN campaign USING(dm_id)
--             JOIN monster USING(dm_id)
--             JOIN monsterencounter USING(dm_id)
--             JOIN monsterparty USING(dm_id)
--             JOIN spell USING(dm_id)
--             JOIN race USING(dm_id);