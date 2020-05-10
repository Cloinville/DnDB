use csuciklo_dndb;

-- DROP VIEW IF EXISTS campaign_players;
-- CREATE VIEW campaign_players 
-- AS
-- SELECT player.player_id,
-- 	   player.player_username,
-- 	   `character`.char_id,
--        `character`.char_name,
--        adventuringparty.party_id,
--        adventuringparty.party_name,
--        campaign.campaign_id,
--        campaign.campaign_name,
--        dungeonmaster.dm_id
-- FROM player JOIN `character` USING(player_id)
-- 			JOIN adventuringparty USING(party_id)
--             JOIN campaign USING(party_id)
--             JOIN dungeonmaster USING(dm_id);
-- TODO: delete?
-- DROP PROCEDURE IF EXISTS get_campaign_previews;
-- DELIMITER $$
-- CREATE PROCEDURE get_campaign_previews(in_player_id VARCHAR(255))
-- BEGIN
-- 	# STUB -> Need to Implement 
-- END $$
-- DELIMITER ;

-- # Create a view for each of the associated entities
-- DROP VIEW IF EXISTS character_abilities;
-- CREATE VIEW character_abilities
-- AS
-- SELECT *
-- FROM characterabilityscore JOIN ability USING(ability_id);

-- DROP VIEW IF EXISTS race_vulnerabilities;
-- CREATE VIEW race_vulnerabilities
-- AS
-- SELECT *
-- FROM vulnerability JOIN damagetype USING(damage_type_id);

-- DROP VIEW IF EXISTS race_resistances;
-- CREATE VIEW race_resistances
-- AS
-- SELECT *
-- FROM resistance JOIN damagetype USING(damage_type_id);

-- DROP VIEW IF EXISTS class_spells;
-- CREATE VIEW class_spells
-- AS
-- SELECT *
-- FROM classlearnablespell JOIN spell USING(spell_id);

-- DROP VIEW IF EXISTS spell_components;
-- CREATE VIEW spell_components
-- AS
-- SELECT *
-- FROM spellcomponent JOIN item USING(item_id);

-- DROP VIEW IF EXISTS monster_abilities;
-- CREATE VIEW monster_abilities
-- AS
-- SELECT *
-- FROM monsterabilityscore JOIN ability USING(ability_id);

-- DROP VIEW IF EXISTS race_ability_modifiers;
-- CREATE VIEW race_ability_modifiers
-- AS
-- SELECT *
-- FROM raceabilityscoremodifier JOIN ability USING(ability_id);

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
	DECLARE modified_entity_name VARCHAR(255) DEFAULT "";
    IF entity IN ("ability_details", "campaign_details", "dungeonmaster_details", "item_details",
				  "language_details", "player_details", "race_details", "schoolofmagic_details",
                  "skill_details", "spell_details", "weapon_details"
				 )
	THEN
		SET modified_entity_name = SUBSTRING_INDEX(entity, "_details", 1);
	ELSE
		SET modified_entity_name = entity;
	END IF;
    
	SELECT column_name, column_type
	FROM INFORMATION_SCHEMA.columns
	WHERE table_schema="csuciklo_dndb"
		  AND table_name = modified_entity_name
		  AND column_key != "MUL";
END $$
DELIMITER ;

# If don't ever use outside of the linked procedure, this can be deleted and
# have its select just moved directly into the procedure that uses it
DROP FUNCTION IF EXISTS get_select_for_foreign_key_columns_and_referenced_table_names;
DELIMITER $$
CREATE FUNCTION get_select_for_foreign_key_columns_and_referenced_table_names(entity VARCHAR(255))
RETURNS TEXT
DETERMINISTIC
BEGIN
	RETURN CONCAT("SELECT column_name, referenced_table_name FROM INFORMATION_SCHEMA.key_column_usage WHERE table_schema = 'csuciklo_dndb' AND table_name = '", entity, "' AND referenced_table_name IS NOT NULL");
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_foreign_key_column_names_and_referenced_table_names;
DELIMITER $$
CREATE PROCEDURE get_foreign_key_column_names_and_referenced_table_names(IN entity VARCHAR(255))
BEGIN
-- 	SELECT COLUMN_NAME, REFERENCED_TABLE_NAME
-- 	FROM INFORMATION_SCHEMA.key_column_usage
-- 	WHERE table_schema="csuciklo_dndb" 
-- 		  AND table_name = entity
--           AND REFERENCED_TABLE_NAME IS NOT NULL;
	SET @query = "";
    SELECT get_select_for_foreign_key_columns_and_referenced_table_names(entity) INTO @query;
    PREPARE stmt FROM @query;
    EXECUTE stmt;
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
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'campaign_id' as 'campaign_id', 'DM' as 'DM', 'Campaign Name' as 'Campaign Name', 'Adventuring Party' as 'Adventuring Party' UNION SELECT 'campaign_id' as 'identifier', 'campaign' as 'entity', campaign_id as 'campaign_id', player_nickname as 'DM', campaign_name as 'Campaign Name', campaign_party_name as 'Adventuring Party' FROM campaign JOIN dungeonmaster USING(dm_id) JOIN player USING(player_id)";
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
	ELSEIF entity = "skill"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'skill_id' as 'skill_id', 'Name' as 'Name', 'Saving Throw' as 'Saving Throw' from skill JOIN ability USING(ability_id) UNION SELECT 'skill_id' as 'identifier', 'skill' as 'entity', skill_id as 'skill_id', skill_name as 'Name', ability_name as 'Saving Throw' from skill LEFT JOIN ability USING(ability_id)";
	ELSEIF entity = "partymember"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'campaign_id' as 'campaign_id', 'DM' as 'DM', 'Campaign Name' as 'Campaign Name', 'Adventuring Party' as 'Adventuring Party' UNION SELECT 'campaign_id' as 'identifier', 'campaign' as 'entity', campaign_id as 'campaign_id', player_nickname as 'DM', campaign_name as 'Campaign Name', campaign_party_name as 'Adventuring Party' FROM campaign JOIN dungeonmaster USING(dm_id) JOIN player USING(player_id) LEFT JOIN partymember USING(campaign_id)";
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

DROP PROCEDURE IF EXISTS get_campaign_previews;
DELIMITER $$
CREATE PROCEDURE get_campaign_previews(in_player_id VARCHAR(255), in_dm_id VARCHAR(255))
BEGIN
	DECLARE search_condition TEXT DEFAULT "";
	IF LOWER(in_dm_id) != "none" AND in_dm_id != ""
    THEN
		SET search_condition = CONCAT("WHERE partymember.player_id = '", in_player_id, "' OR dm_id = '", in_dm_id, "'");
	ELSE
		SET search_condition = CONCAT("WHERE partymember.player_id = '", in_player_id, "'");
	END IF;
    SET @select = get_select_for_entity_previews("partymember");
    SET @query = CONCAT(@select, " ", search_condition);
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

# TODO: possibly replace all instances of above function w/this one
# This function is only ever called for base entities, not associative
# "condition" == "creator condition" ie. gets display names for records where in_player_id was creator
DROP PROCEDURE IF EXISTS get_displayname_displaycolname_fkvalue_fkcolname_with_condition;
DELIMITER $$
CREATE PROCEDURE get_displayname_displaycolname_fkvalue_fkcolname_with_condition(entity VARCHAR(255), in_player_id VARCHAR(255))
BEGIN
    IF entity = "dungeonmaster" 
    THEN
		SELECT CONCAT(player_nickname, ' ( ', player_username, ' ) '), "CONCAT(player_nickname, ' ( ', player_username, ' ) ')", dm_id, 'dm_id' FROM dungeonmaster JOIN player USING(player_id) WHERE dungeonmaster.player_id = in_player_id; 
	ELSE
		IF entity = "character"
        THEN
			SET @condition = CONCAT("WHERE player_id = ", in_player_id);
		ELSE
			SET @condition = CONCAT("WHERE dm_id = (SELECT dm_id FROM dungeonmaster WHERE player_id = ", in_player_id, ")");
		END IF;
        
		IF entity = "monsterencounter" 
        THEN 
			SET @query = CONCAT("SELECT monster_name, 'monster_name', monster_id, 'monster_id' FROM monster JOIN monsterencounter USING(monster_id)", " ", @condition);
		ELSEIF entity = "weapon" 
        THEN 
			SET @query = CONCAT("SELECT item_name, 'item_name', item_id, 'item_id' FROM weapon JOIN item USING(item_id)", " ", @condition);
		ELSE 
			SET @query = CONCAT("SELECT ", get_comma_separated_displayname_displaycolname_fkvalue_fkcolname(entity), " FROM ", entity, " ", @condition);
		END IF;

		PREPARE stmt FROM @query;
		EXECUTE stmt;
	END IF;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_display_vals_for_fk_records_with_member_condition;
DELIMITER $$
CREATE PROCEDURE get_display_vals_for_fk_records_with_member_condition(in_player_id VARCHAR(255))
BEGIN
	SET @query = CONCAT("SELECT ", get_comma_separated_displayname_displaycolname_fkvalue_fkcolname("campaign"), 
						" FROM campaign JOIN partymember USING(campaign_id) WHERE player_id = ", in_player_id, 
                        " AND char_id IS NULL");
    PREPARE stmt FROM @query;
    EXECUTE stmt;
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

# TODO - Need to update views switch cases if add more records than can be created by users
DROP PROCEDURE IF EXISTS update_field_in_record;
DELIMITER $$
CREATE PROCEDURE update_field_in_record(in_table VARCHAR(255), in_field VARCHAR(255), new_value VARCHAR(255), record_id_value VARCHAR(255))
BEGIN
	DECLARE formatted_in_table VARCHAR(255) DEFAULT "";
    DECLARE record_id_name VARCHAR(255) DEFAULT "";
    
    IF in_table LIKE "%_details"
    THEN
		SET formatted_in_table = SUBSTRING_INDEX(in_table, "_details", 1);
        SET record_id_name = get_primary_key_name_from_table_name(formatted_in_table);
	ELSE
		SET formatted_in_table = in_table;
        SET record_id_name = get_primary_key_name_from_table_name(in_table);
	END IF;
    
    IF formatted_in_table = "character" OR formatted_in_table = "language"
	THEN
		SET formatted_in_table = CONCAT("`", formatted_in_table, "`");
	END IF;

	SET @query = CONCAT("UPDATE ", formatted_in_table, " SET ", in_field, " = ", "'", new_value, "' WHERE ", record_id_name, " = ", record_id_value);
	PREPARE stmt FROM @query;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_select_stmt_for_all_associated_table_and_fkcol_names;
DELIMITER $$
CREATE FUNCTION get_select_stmt_for_all_associated_table_and_fkcol_names(in_table VARCHAR(255))
RETURNS TEXT
DETERMINISTIC
BEGIN
IF in_table = 'monsterparty'
     THEN
 		RETURN CONCAT("SELECT key_cols.table_name as 'table_name', key_cols.table_name as 'referenced_table_name', cols.column_name as 'referenced_column_name' FROM INFORMATION_SCHEMA.key_column_usage as key_cols JOIN INFORMATION_SCHEMA.columns as cols USING(table_name) WHERE key_cols.table_schema = 'csuciklo_dndb' AND key_cols.referenced_table_name = '", in_table, "' AND column_key = 'PRI'");
 	ELSE
		RETURN CONCAT("SELECT table_name, referenced_table_name, referenced_column_name FROM INFORMATION_SCHEMA.key_column_usage WHERE table_schema='csuciklo_dndb' AND table_name IN (SELECT table_name FROM INFORMATION_SCHEMA.key_column_usage WHERE table_schema='csuciklo_dndb' AND referenced_table_name = '", in_table, "') AND REFERENCED_TABLE_NAME IS NOT NULL AND REFERENCED_TABLE_NAME != '", in_table, "'");
 	END IF;
END $$
DELIMITER ;

# Is this still used???
DROP PROCEDURE IF EXISTS get_all_associated_table_and_fkcol_names;
DELIMITER $$
CREATE PROCEDURE get_all_associated_table_and_fkcol_names(in_table VARCHAR(255))
BEGIN
	SET @query = "";
	SELECT get_select_stmt_for_all_associated_table_and_fkcol_names(in_table) INTO @query;
    PREPARE stmt FROM @query;
    EXECUTE stmt;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_associated_table_and_fkcol_names_using_condition;
DELIMITER $$
CREATE PROCEDURE get_associated_table_and_fkcol_names_using_condition(in_table VARCHAR(255), in_condition TEXT)
BEGIN
	DECLARE base_query TEXT DEFAULT "";
 	SELECT get_select_stmt_for_all_associated_table_and_fkcol_names(in_table) INTO base_query;   
	SET @query = CONCAT(base_query, " ", in_condition);
    PREPARE stmt FROM @query;
    EXECUTE stmt;
END $$
DELIMITER ;

# TODO: rename this
DROP PROCEDURE IF EXISTS get_associated_table_and_fkcol_names_for_create;
DELIMITER $$
CREATE PROCEDURE get_associated_table_and_fkcol_names_for_create(in_table VARCHAR(255))
BEGIN
	DECLARE select_condition TEXT DEFAULT "";
    IF in_table = 'campaign'
    THEN
		SET select_condition = "AND table_name != 'dungeonmaster' AND table_name != 'monsterparty' AND table_name != 'monster' AND referenced_table_name != 'character'";
	ELSEIF in_table = 'character'
    THEN
		SET select_condition = "AND referenced_table_name != 'player' AND referenced_table_name != 'class'";
    ELSEIF in_table = 'class'
    THEN
		SET select_condition = "AND table_name != 'levelallocation'";
	ELSEIF in_table = 'item'
    THEN
		SET select_condition = "AND table_name != 'monsterlootitem' AND table_name != 'characterinventoryitem' AND table_name != 'weapon'";
	ELSEIF in_table = 'language'
    THEN
		SET select_condition = "AND table_name != 'characterlearnedlanguage'";
	ELSEIF in_table = 'monster'
    THEN
		SET select_condition = "AND table_name != 'monsterencounter'";
    ELSEIF in_table = 'race'
    THEN 
		SET select_condition = "AND table_name != 'character'";
	ELSEIF in_table = 'spell'
    THEN
		SET select_condition = "AND table_name != 'learnedspell'";
	END IF;
    CALL get_associated_table_and_fkcol_names_using_condition(in_table, select_condition);
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS character_owned_by_player;
DELIMITER $$
CREATE FUNCTION character_owned_by_player(in_char_id INT(10), in_player_id INT(10))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
	IF in_char_id IS NULL
    THEN
		RETURN TRUE;
	ELSE
		RETURN (SELECT count(*) > 0 FROM `character` WHERE char_id = in_char_id AND player_id = in_player_id);
	END IF;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS insert_record;
DELIMITER $$
CREATE PROCEDURE insert_record(in_table VARCHAR(255), in_col_list TEXT, in_values TEXT)
BEGIN
	DECLARE usable_tbl_name VARCHAR(255) DEFAULT "";
    DECLARE in_col_addition VARCHAR(255) DEFAULT "";
    
	IF in_table = "character" OR in_table = "language"
	THEN
		SELECT CONCAT("`", in_table, "`") INTO usable_tbl_name;
	ELSE
		SELECT in_table INTO usable_tbl_name;
    END IF;
    IF in_table = "characterabilityscore"
    THEN
		SET in_col_addition = ",charabilityscore_value";
	END IF;
    
    SET @query = CONCAT("INSERT INTO ", usable_tbl_name, "(", in_col_list, in_col_addition, ") VALUES(", in_values, ")");
    PREPARE stmt FROM @query;
    EXECUTE stmt;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS conditional_partymember_record_insert_for_character;
DELIMITER $$
CREATE PROCEDURE conditional_partymember_record_insert_for_character(in_char_id VARCHAR(255), in_player_id VARCHAR(255), in_campaign_id VARCHAR(255))
BEGIN
	IF EXISTS (SELECT char_id FROM partymember WHERE campaign_id = in_campaign_id AND player_id = in_player_id)
    THEN
		IF (SELECT char_id FROM partymember WHERE campaign_id = in_campaign_id AND player_id = in_player_id) IS NULL
		THEN
			UPDATE partymember SET char_id = in_char_id WHERE campaign_id = in_campaign_id AND player_id = in_player_id;
		END IF;
	ELSE
		INSERT INTO partymember(campaign_id, player_id, char_id) VALUES(in_campaign_id, in_player_id, in_char_id);
	END IF;
END $$
DELIMITER ;

# Saved for potential future use, but if don't add anything then we can delete it
DROP PROCEDURE IF EXISTS get_most_recent_pk_val_and_pk_colname;
DELIMITER $$
CREATE PROCEDURE get_most_recent_pk_val_and_pk_colname(in_table VARCHAR(255))
BEGIN
	DECLARE pk_name VARCHAR(255) DEFAULT "";
    DECLARE usable_tbl_name VARCHAR(255) DEFAULT "";
    
    IF in_table = "character" OR in_table = "language"
    THEN
		SET usable_tbl_name = CONCAT("`", in_table, "`");
	ELSE
		SELECT in_table INTO usable_tbl_name;
	END IF;
        
    SELECT get_primary_key_name_from_table_name(in_table) INTO pk_name;
    
    SET @query = CONCAT("SELECT IFNULL(MAX(", pk_name, "), 0), '", pk_name, "' FROM ", usable_tbl_name, "");
	PREPARE stmt FROM @query;
	EXECUTE stmt;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_newspells_count_for_class_at_level;
DELIMITER $$
CREATE PROCEDURE get_newspells_count_for_class_at_level(in_class_id VARCHAR(255), in_level VARCHAR(255))
BEGIN
	WITH curr_level
	AS
		(SELECT newspellscount_cantrips, 
				newspellscount_spell_slots_level_1,
				newspellscount_spell_slots_level_2,
				newspellscount_spell_slots_level_3,
				newspellscount_spell_slots_level_4,
				newspellscount_spell_slots_level_5,
				newspellscount_spell_slots_level_6,
				newspellscount_spell_slots_level_7,
				newspellscount_spell_slots_level_8,
				newspellscount_spell_slots_level_9
		FROM classlevelnewspellscount WHERE class_id = in_class_id AND newspellscount_class_level = in_level)
	SELECT curr_level.newspellscount_cantrips - prev_level.newspellscount_cantrips as "New Cantrips", 
		   curr_level.newspellscount_spell_slots_level_1 - prev_level.newspellscount_spell_slots_level_1 as "New Level 1",
		   curr_level.newspellscount_spell_slots_level_2 - prev_level.newspellscount_spell_slots_level_2 as "New Level 2",
		   curr_level.newspellscount_spell_slots_level_3 - prev_level.newspellscount_spell_slots_level_3 as "New Level 3",
           curr_level.newspellscount_spell_slots_level_4 - prev_level.newspellscount_spell_slots_level_4 as "New Level 4",
           curr_level.newspellscount_spell_slots_level_5 - prev_level.newspellscount_spell_slots_level_5 as "New Level 5",
           curr_level.newspellscount_spell_slots_level_6 - prev_level.newspellscount_spell_slots_level_6 as "New Level 6",
           curr_level.newspellscount_spell_slots_level_7 - prev_level.newspellscount_spell_slots_level_7 as "New Level 7",
           curr_level.newspellscount_spell_slots_level_8 - prev_level.newspellscount_spell_slots_level_8 as "New Level 8",
           curr_level.newspellscount_spell_slots_level_9 - prev_level.newspellscount_spell_slots_level_9 as "New Level 9"
	FROM classlevelnewspellscount as prev_level JOIN curr_level ON prev_level.class_id = in_class_id AND prev_level.newspellscount_class_level = (SELECT in_level - 1);
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_open_campaigns_of_player;
DELIMITER $$
CREATE PROCEDURE get_open_campaigns_of_player(in_player_id VARCHAR(255))
BEGIN
	SELECT campaign_id FROM partymember WHERE player_id = in_player_id AND char_id IS NULL;
END $$
DELIMITER ;

# STUB - fill in with grab from Views?
# VIEW FROM: 1st row as col name; 2nd row as Data type info
DROP PROCEDURE IF EXISTS get_direct_entity_details;
DELIMITER $$
CREATE PROCEDURE get_direct_entity_details(entity VARCHAR(255), primary_key_value VARCHAR(255), in_player_id INT)
BEGIN
	DECLARE creator_id INT DEFAULT NULL;
	DECLARE allow_edits VARCHAR(255) DEFAULT "NO";
    # 5/7 STUB
    IF entity = "ability"
    THEN
		SELECT "NO", "NO", "NO"
        UNION ALL
		SELECT * FROM ability WHERE ability_id = primary_key_value;
	ELSEIF entity = "campaign"
    THEN
		# 5/7 STUB
        SELECT "NO", "YES", "YES", "YES", "YES", "NO", "YES"
        UNION ALL
        SELECT * FROM campaign WHERE campaign_id = primary_key_value;
-- 		IF EXISTS (SELECT * FROM dungeonmaster WHERE player_id = in_player_id LIMIT 1)
--         THEN
-- 			SELECT *, "PRIVATE VIEW" FROM campaign WHERE campaign_id = primary_key_value;
-- 		ELSE
-- 			SELECT *, "PUBLIC VIEW" FROM campaign WHERE campaign_id = primary_key_value;
-- 		END IF;
	ELSEIF entity = "character"
    THEN
		# 5/7 FULLY IMPLEMENTED
		SET creator_id = (SELECT player_id FROM `character` WHERE char_id = primary_key_value AND player_id = in_player_id);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
		END IF;
        SELECT "NO" as "ID",
		       allow_edits as "char_name", 
			   "NO" as "player_nickname",
		       allow_edits as "char_gender",
               "NO" as "char_overall_level", 
               "NO" as "race_name", 
               "NO" as "race_speed", 
               "NO" as "race_size", 
               allow_edits as "char_backstory", 
               allow_edits as "char_age", 
               allow_edits as "char_height",
		       allow_edits as "char_notes", 
               allow_edits as "char_public_class", 
               allow_edits as "char_base_hp", 
               allow_edits as "char_hp_remaining",
               allow_edits as "char_platinum", 
               allow_edits as "char_gold", 
               allow_edits as "char_silver", 
               allow_edits as "char_copper"
		UNION ALL
		SELECT * FROM character_details WHERE ID = primary_key_value;
	ELSEIF entity = "characterabilityscore"
    THEN
		# 5/7 probably fully implemented??
-- 		SET creator_id = (SELECT player_id FROM `character` WHERE char_id = primary_key_value AND player_id = in_player_id);
--         IF creator_id IS NOT NULL
--         THEN
-- 			SET allow_edits = "YES";
-- 		END IF;
        # FINISH
        SELECT
				"NO" as "ID",
                "NO" as "Ability Name",
                "NO" as "Value"
        UNION ALL
        SELECT * FROM characterabilityscore_details WHERE ID = primary_key_value;
	ELSEIF entity = "characterinventoryitem"
    THEN
		# 5/7 STUB
		SELECT "NO", "NO"
        UNION ALL
		SELECT * FROM characterinventoryitem_details WHERE ID = primary_key_value;
	ELSEIF entity = "characterlearnedlanguage"
    THEN
		# 5/7 STUB
		SELECT "NO", "NO"
        UNION ALL
        SELECT * FROM characterlearnedlanguage_details WHERE ID = primary_key_value;
	ELSEIF entity = "class"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO", "NO", "NO"
        UNION ALL
        SELECT * FROM class WHERE class_id = primary_key_value;
	ELSEIF entity = "classlearnablespell"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO"
        UNION ALL
        SELECT * FROM classlearnablespell_details WHERE ID = primary_key_value;
	ELSEIF entity = "classlevelnewspellcount"
	THEN
		# 5/7 STUB
        SELECT "NO", "NO"
        UNION ALL
        SELECT * FROM classlevelnewspellscount_details WHERE ID = primary_key_value;
	ELSEIF entity = "dungeonmaster"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO"
        UNION ALL
		SELECT * FROM dungeonmaster WHERE dm_id = primary_key_value;
	ELSEIF entity = "item"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO"
        UNION ALL
		SELECT * FROM item WHERE item_id = primary_key_value;
	ELSEIF entity = "language"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO"
        UNION ALL
		SELECT * FROM `language` WHERE language_id = primary_key_value;
	ELSEIF entity = "learnedspell"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO"
        UNION ALL
        SELECT * FROM learnedspell_details WHERE ID = primary_key_value;
	ELSEIF entity = "levelallocation"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO"
        UNION ALL
        SELECT * FROM levelallocation_details WHERE ID = primary_key_value;
	ELSEIF entity = "monster"
    THEN
		# 5/7 Fully Implemented
		SET creator_id = (SELECT player_id FROM monster JOIN dungeonmaster USING(dm_id) WHERE monster_id = primary_key_value AND player_id = in_player_id LIMIT 1);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
        END IF;
        
		SELECT allow_edits as "ID",
			   allow_edits as "Name", 
		       allow_edits as "Armor Class",
		       allow_edits as "Challenge Rating",
               allow_edits as "Description", 
               allow_edits as "Base HP", 
               allow_edits as "Creator"
		UNION ALL
        SELECT * FROM monster_details WHERE ID = primary_key_value;
	ELSEIF entity = "monsterabilityscore"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO"
        UNION ALL
        SELECT * FROM monsterabilityscore_details WHERE ID = primary_key_value;
	ELSEIF entity = "monsterencounter"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "YES"
        UNION ALL
        SELECT * FROM monsterencounter_details WHERE ID = primary_key_value;
	ELSEIF entity = "monsterparty_monsterencounter"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO", "NO"
        UNION ALL
		SELECT * FROM monsterparty_monsterencounter_details WHERE ID = primary_key_value;
	ELSEIF entity = "monsterlootitem"
    THEN
		SELECT "NO", "NO"
        UNION ALL
        SELECT * FROM monsterlootitem_details WHERE ID = primary_key_value;
	ELSEIF entity = "monsterparty"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO"
        UNION ALL
		SELECT * FROM monsterparty_details WHERE ID = primary_key_value;
-- 	ELSEIF entity = "partymember"
--     THEN
-- 		# 5/7 STUB
--         SELECT "NO", "NO", "NO"
--         UNION ALL
--         SELECT * FROM partymember_details WHERE ID = primary_key_value;
	ELSEIF entity = "player_partymember"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO"
        UNION ALL
        SELECT * FROM player_partymember_details WHERE ID = primary_key_value;
	ELSEIF entity = "character_partymember"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO"
        UNION ALL
        SELECT * FROM character_partymember_details WHERE ID = primary_key_value;
	ELSEIF entity = "player"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO", "NO"
        UNION ALL
		SELECT * FROM player WHERE player_id = primary_key_value;
	ELSEIF entity = "race"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO", "NO", "NO", "NO", "NO"
        UNION ALL
		SELECT * FROM race WHERE race_id = primary_key_value;
	ELSEIF entity = "raceabilityscoremodifier"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO"
        UNION ALL
        SELECT * FROM raceabilityscoremodifier_details WHERE ID = primary_key_value;
	ELSEIF entity = "raceknownlanguage"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO"
        UNION ALL
        SELECT * FROM raceknownlanguage_details WHERE ID = primary_key_value;
	ELSEIF entity = "schoolofmagic"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO"
        UNION ALL
		SELECT * FROM schoolofmagic WHERE magicschool_id = primary_key_value;
	ELSEIF entity = "skill"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO", "NO", "NO"
        UNION ALL
		SELECT * FROM skill WHERE skill_id = primary_key_value;
	ELSEIF entity = "spell"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO"
        UNION ALL
		SELECT * FROM spell WHERE spell_id = primary_key_value;
	ELSEIF entity = "weapon"
    THEN
		# 5/7 STUB
        SELECT "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO", "NO"
        UNION ALL
		SELECT * FROM weapon LEFT JOIN item USING(item_id) WHERE weapon_id = primary_key_value;
	END IF;
END $$
DELIMITER ;


# ** EDITABLE FIELDS VIEWS -> get fk, non fk stuff pulls from these, instead of tables themselves
# TODO: combine with just the "readonly details" piece
DROP VIEW IF EXISTS character_details;
CREATE VIEW character_details
AS
    SELECT char_id as "ID",
		   char_name as "char_name", 
		   player_nickname as "player_nickname",
		   char_gender as "char_gender",
           char_overall_level as "char_overall_level", 
           race_name as "race_name", 
           race_speed as "race_speed", 
           race_size as "race_size", 
           char_backstory as "char_backstory", 
           char_age as "char_age", 
           char_height as "char_height",
		   char_notes as "char_notes", 
           char_public_class as "char_public_class", 
           char_base_hp as "char_base_hp", 
           char_hp_remaining as "char_hp_remaining",
           char_platinum as "char_platinum", 
           char_gold as "char_gold", 
           char_silver as "char_silver", 
           char_copper as "char_copper"
    FROM `character` JOIN race USING(race_id) 
		             JOIN player USING(player_id);
                     
-- DROP VIEW IF EXISTS character_details_with_readonly_info;
-- CREATE VIEW character_details_with_readonly_info
-- AS
--     SELECT "NO" as "ID",
-- 		   "YES" as "Name", 
-- 		   "NO" as "Player",
-- 		   "YES" as "Gender",
--            "NO" as "Level", 
--            "NO" as "Race", 
--            "NO" as "Speed", 
--            "NO" as "Size", 
--            "YES" as "Backstory", 
--            "YES" as "Age", 
--            "YES" as "Height",
-- 		   "YES" as "Notes", 
--            "YES" as "Public Class", 
--            "YES" as "Base HP", 
--            "YES" as "Remaining HP",
--            "YES" as "Platinum", 
--            "YES" as "Gold", 
--            "YES" as "Silver", 
--            "YES" as "Copper"
-- 	UNION ALL
--     SELECT * FROM character_details;
    
DROP VIEW IF EXISTS monster_details;
CREATE VIEW monster_details
AS
    SELECT monster_id as "ID",
		   monster_name as "Name", 
		   monster_ac as "Armor Class",
		   monster_challenge_rating as "Challenge Rating",
           monster_description as "Description", 
           monster_base_hp as "Base HP", 
           player_nickname as "Creator"
    FROM monster LEFT JOIN dungeonmaster USING(dm_id) 
			     LEFT JOIN player USING(player_id);
                 
DROP VIEW IF EXISTS characterabilityscore_details;
CREATE VIEW characterabilityscore_details
AS
    SELECT char_id as "ID",
		   ability_name as "Ability Name", 
		   charabilityscore_value as "Value"
    FROM characterabilityscore JOIN ability USING(ability_id);

# 5/7 STUB
DROP VIEW IF EXISTS characterinventoryitem_details;
CREATE VIEW characterinventoryitem_details
AS
    SELECT char_id as "ID",
		   item_name as "Item Name"
    FROM characterinventoryitem JOIN item USING(item_id)
										LEFT JOIN weapon USING(item_id);

# 5/7 STUB
DROP VIEW IF EXISTS characterlearnedlanguage_details;
CREATE VIEW characterlearnedlanguage_details
AS
    SELECT char_id as "ID",
		   language_name as "Language Name"
    FROM characterlearnedlanguage JOIN `language` USING(language_id);

# 5/7 STUB
DROP VIEW IF EXISTS learnedspell_details;
CREATE VIEW learnedspell_details
AS
    SELECT char_id as "ID",
		   spell_name as "Spell Name"
    FROM learnedspell JOIN spell USING(spell_id);
    
# 5/7 STUB
DROP VIEW IF EXISTS levelallocation_details;
CREATE VIEW levelallocation_details
AS
    SELECT char_id as "ID",
		   class_name as "Class Name",
           levelallocation_level as "Levels"
    FROM levelallocation JOIN class USING(class_id);

# 5/7 STUB
DROP VIEW IF EXISTS monsterabilityscore_details;
CREATE VIEW monsterabilityscore_details
AS
    SELECT monster_id as "ID",
		   ability_name as "Ability Name", 
		   monsterabilityscore_value as "Value"
    FROM monsterabilityscore JOIN ability USING(ability_id);

# 5/7 STUB
DROP VIEW IF EXISTS monsterencounter_details;
CREATE VIEW monsterencounter_details
AS
    SELECT encounter_id as "ID",
		   monster_name as "Monster Name",
           encounter_hp_remaining as "HP Remaining"
    FROM monsterencounter JOIN monster USING(monster_id) JOIN monsterparty USING(monsterparty_id);
    
# 5/7 STUB(?)
DROP VIEW IF EXISTS monsterparty_monsterencounter_details;
CREATE VIEW monsterparty_monsterencounter_details
AS
	SELECT monsterparty_id as "ID",
		   monster_name as "Monster Name",
		   encounter_hp_remaining as "HP Remaining",
           group_concat(item_name ORDER BY item_name SEPARATOR', ') as "Loot Items"
	FROM monsterparty JOIN monsterencounter USING(monsterparty_id)
					  JOIN monster USING(monster_id) 
					  LEFT JOIN monsterlootitem USING(encounter_id)
					  LEFT JOIN item USING(item_id)
	GROUP BY encounter_id;

# 5/8 WIP
DROP VIEW IF EXISTS monsterencounter_monsterencounter_details;
CREATE VIEW monsterencounter_monsterencounter_details
AS 
	SELECT encounter_id as "ID",
		   monster_name as "Monster Name",
           encounter_hp_remaining as "HP Remaining"
	FROM monsterencounter JOIN monster USING(monster_id) JOIN monsterparty USING(monsterparty_id);

# 5/7 STUB
DROP VIEW IF EXISTS monsterlootitem_details;
CREATE VIEW monsterlootitem_details
AS
    SELECT encounter_id as "ID",
		   item_name as "Item Name"
    FROM monsterlootitem JOIN monsterencounter USING(encounter_id) JOIN item USING(item_id) LEFT JOIN weapon USING(item_id);
    
# 5/7 STUB - also, almost certainly incorrect
DROP VIEW IF EXISTS monsterparty_details;
CREATE VIEW monsterparty_details
AS
    SELECT monsterparty_id as "ID",
		   monsterparty_location as "Location"
    FROM monsterparty;
    
# 5/7 STUB
DROP VIEW IF EXISTS player_partymember_details;
CREATE VIEW player_partymember_details
AS
    SELECT campaign_id as "ID",
		   player_nickname as "Player Nickname",
           char_name as "Character Name"
    FROM partymember JOIN player USING(player_id) LEFT JOIN `character` USING(char_id);

# 5/7 STUB
DROP VIEW IF EXISTS character_partymember_details;
CREATE VIEW character_partymember_details
AS
    SELECT char_id as "ID",
           campaign_name as "Campaign Name"
    FROM partymember JOIN campaign USING(campaign_id);

# 5/7 STUB
DROP VIEW IF EXISTS raceabilityscoremodifier_details;
CREATE VIEW raceabilityscoremodifier_details
AS
    SELECT race_id as "ID",
		   ability_name as "Ability Name",
           racemodifier_value as "Modifier Value"
    FROM raceabilityscoremodifier JOIN ability USING(ability_id);

# 5/7 STUB
DROP VIEW IF EXISTS raceknownlanguage_details;
CREATE VIEW raceknownlanguage_details
AS
    SELECT race_id as "ID",
		   language_name as "Language"
    FROM raceknownlanguage JOIN `language` USING(language_id);
    
DROP VIEW IF EXISTS classlearnablespell_details;
CREATE VIEW classlearnablespell_details
AS
    SELECT class_id as "ID",
		   cls_required_class_level as "cls_required_class_level",
		   spell_name as "Spell Name"
    FROM classlearnablespell JOIN spell USING(spell_id);
    
DROP VIEW IF EXISTS classlevelnewspellscount_details;
CREATE VIEW classlevelnewspellscount_details
AS
    SELECT class_id as "ID",
		   newspellscount_class_level as "Class Level"
    FROM classlevelnewspellscount;

# TODO: TEST!
DROP TRIGGER IF EXISTS characterinventoryitem_autoincrement;
DELIMITER $$
CREATE TRIGGER characterinventoryitem_autoincrement
BEFORE
INSERT ON characterinventoryitem
FOR EACH ROW
BEGIN
	SET NEW.characterinventoryitem_counter = ( SELECT IFNULL(MAX(characterinventoryitem_counter), 0) + 1
											   FROM characterinventoryitem
                                               WHERE char_id = NEW.char_id AND item_id = NEW.item_id
											 );
END $$
DELIMITER ;

# TODO: TEST!
DROP TRIGGER IF EXISTS monsterlootitem_autoincrement;
DELIMITER $$
CREATE TRIGGER monsterlootitem_autoincrement
BEFORE
INSERT ON monsterlootitem
FOR EACH ROW
BEGIN
	SET NEW.monsterlootitem_counter = ( SELECT IFNULL(MAX(monsterlootitem_counter), 0) + 1
											   FROM monsterlootitem
                                               WHERE encounter_id = NEW.encounter_id AND item_id = NEW.item_id
											 );
END $$
DELIMITER ;

# HOW ABOUT NOT... -> 5/3 TODO: get_associated_..._for_update => as w/monsterparty, do edit for campaign that brings in monsterparties