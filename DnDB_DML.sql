# use csuciklo_dndb;
USE csuciklo_COMP420_DnDB;

# File Contents:
#       1. 5 Required Views
#       2. 12 Required Functions & Procedures
#       3. 3 Required Triggers
#       4. Miscellaneous Triggers
#       5. Miscellaneous Functions & Procedures
#       6. Miscellaneous Views

-- ------------------------------------------- 5 Required Views ------------------------------------------- --

# 1. Character view, with all in-record fields as well as concatenated information regarding all 
#    associated levelallocations both re:the classes that the character has taken level(s) in, as well
#    as the number of levels taken in each class
DROP VIEW IF EXISTS character_details;
CREATE VIEW character_details
AS
    SELECT char_id as "ID",
		   char_name as "Name", 
		   player_nickname as "Player",
		   char_gender as "Gender",
           char_overall_level as "Overall Level",
           group_concat(CONCAT(class_name, ": ", levelallocation_level) SEPARATOR", ") as "Level Allocation",
           race_name as "Race", 
           race_speed as "Speed", 
           race_size as "Size", 
           char_backstory as "Backstory", 
           char_age as "Age", 
           char_height as "Height",
		   char_notes as "Notes", 
           char_public_class as "Public Class", 
           char_base_hp as "Base HP", 
           char_remaining_hp as "Remaining HP",
           char_platinum as "Platinum", 
           char_gold as "Gold", 
           char_silver as "Silver", 
           char_copper as "Copper"
    FROM `character` JOIN race USING(race_id) 
		             JOIN player USING(player_id)
                     LEFT JOIN levelallocation USING(char_id)
                     LEFT JOIN class USING(class_id) 
                     GROUP BY char_id;
                     
# 2. Joins the information held in the Weapon table with its associated Item and creator information
#    to save on repetitive re-joins
DROP VIEW IF EXISTS weapon_details;	
CREATE VIEW weapon_details	
AS	
    SELECT item_id as "ID",	
		   item_name as "Item",	
           item_description as "Description",
           item_rarity as "Rarity",
           item_type as "Type",
           item_price as "Price",
           item_requires_attunement as "Requires Attunement",
		   weapon_num_dice_to_roll as "Roll",	
		   weapon_damage_modifier  as "Damage Mod",	
		   weapon_range as "Range",	
		   damage_type as "Damage Type"	,
           CONCAT(player_nickname, ' (', player_username, ')') as "Creator"
    FROM weapon LEFT JOIN item USING (item_id)
                LEFT JOIN dungeonmaster USING(dm_id)
                LEFT JOIN player USING(player_id);
                
# 3. Relevant information regarding monsterencounter and a subset of their associated entities as viewed from the monsterparty that monsterencounter belongs to
DROP VIEW IF EXISTS monsterparty_monsterencounter_details;
CREATE VIEW monsterparty_monsterencounter_details
AS
	SELECT monsterparty_id as "ID",
		   encounter_id as "encounter_id",
		   monster_name as "Monster Name",
		   encounter_hp_remaining as "HP Remaining",
           group_concat(item_name ORDER BY item_name SEPARATOR', ') as "Loot Items"
	FROM monsterparty JOIN monsterencounter USING(monsterparty_id)
					  JOIN monster USING(monster_id) 
					  LEFT JOIN monsterlootitem USING(encounter_id)
					  LEFT JOIN item USING(item_id)
	GROUP BY encounter_id;
    
# 4. Collects the publically known information about each character in reference to the campaign they belong to
#    (or NULLs if the player has not yet assigned a character to the campaign)
#    to be returned to other players in that campaign in lieu of all campaign and associated entities' details
DROP VIEW IF EXISTS public_campaign_partymember_details;
CREATE VIEW public_campaign_partymember_details
AS
    SELECT campaign_id as "ID",
		   player_nickname as "Player",
           char_name as "Character Name",
           char_public_class as "Class"
    FROM partymember JOIN player USING(player_id) 
                     LEFT JOIN `character` USING(char_id);

# 5. Collects for display all keymost details of each character attached to the campaign and the character's associated level allocations and inventory items
#    for the DM's reference
DROP VIEW IF EXISTS private_campaign_partymember_details;
CREATE VIEW private_campaign_partymember_details
AS
	# Handles case where character either doesn't exist, or exists and has inventory items
	SELECT campaign_id as "ID", 
		   player_nickname as "Player",
	       character_details.Name,
           character_details.Gender,
           character_details.`Overall Level`,
           character_details.`Level Allocation`,
           character_details.Race,
           character_details.Speed,
           character_details.Size,
           character_details.Backstory,
           character_details.Notes,
           character_details.`Base HP`,
           (character_details.Platinum * 10) + character_details.Gold + (character_details.Silver / .1) + (character_details.Copper / .01) as "Money",
           group_concat(`Item` ORDER BY `Item` SEPARATOR', ') as "Inventory"
	FROM campaign JOIN partymember USING(campaign_id)
                  LEFT JOIN player USING(player_id)
                  LEFT JOIN character_details ON partymember.char_id = character_details.ID
				  LEFT JOIN characterinventoryitem_details ON character_details.ID = characterinventoryitem_details.ID
	GROUP BY character_details.ID
	HAVING  character_details.ID IS NOT NULL
	UNION
    # Case where character exists but has no inventory items
	SELECT campaign_id as "ID", 
		   player_nickname as "Player",
	       character_details.Name,
           character_details.Gender,
           character_details.`Overall Level`,
           character_details.`Level Allocation`,
           character_details.Race,
           character_details.Speed,
           character_details.Size,
           character_details.Backstory,
           character_details.Notes,
           character_details.`Base HP`,
           (character_details.Platinum * 10) + character_details.Gold + (character_details.Silver / .1) + (character_details.Copper / .01) as "Money",
           NULL as "Inventory"
	FROM campaign JOIN partymember USING(campaign_id)
                  LEFT JOIN player USING(player_id)
                  LEFT JOIN character_details ON partymember.char_id = character_details.ID
                  LEFT JOIN characterinventoryitem_details ON characterinventoryitem_details.ID = character_details.ID
	WHERE characterinventoryitem_details.item_id IS NULL;
    

-- ------------------------------------------- 12 Required Functions & Procedures ------------------------------------------- --

# 1. Attempts to add the specified character as the character of the indicated player for the indicated campaign.
#    by either creating a new record - if no PartyMember record linking the campaign to the player exists -
#    or by updating the existing record for that corresponding PartyMember.
#
#    If no campaign ID is specified or the Character of the corresponding PartyMember is non-null, then
#    no action is taken.
#
#   Thus, enforces several restrictions:
#         1. The character must belong to the player
#         2. The player must not already have a character linked to that campaign
DROP PROCEDURE IF EXISTS conditional_partymember_record_insert_for_character;
DELIMITER $$
CREATE PROCEDURE conditional_partymember_record_insert_for_character(in_char_id VARCHAR(255), in_player_id VARCHAR(255), in_campaign_id VARCHAR(255))
BEGIN
	IF in_campaign_id != "" and (SELECT player_id FROM `character` WHERE char_id = in_char_id LIMIT 1) = in_player_id
    THEN
		# If player is a member of the campaign
		IF EXISTS (SELECT campaign_id FROM partymember WHERE campaign_id = in_campaign_id AND player_id = in_player_id)
		THEN
			# If player doesn't yet have a character linked to the campaign
			IF (SELECT char_id FROM partymember WHERE campaign_id = in_campaign_id AND player_id = in_player_id) IS NULL
			THEN
				# Then link the character to the campaign ; Otherwise, do nothing
				UPDATE partymember SET char_id = in_char_id WHERE campaign_id = in_campaign_id AND player_id = in_player_id;
			END IF;
		ELSE
			# If player not yet a member of the campaign, then make them a player, and link the character to the campaign
			INSERT INTO partymember(campaign_id, player_id, char_id) VALUES(in_campaign_id, in_player_id, in_char_id);
		END IF;
	END IF;
END $$
DELIMITER ;

# 2. Generates and returns the prompt string used to help players to determine how to calculate their
#    new hit points upon taking a level in the indicated class.
#    Used as a subcomponent of the level up special process
DROP FUNCTION IF EXISTS get_level_up_hp_calc_str_for_character;
DELIMITER $$
CREATE FUNCTION get_level_up_hp_calc_str_for_character(in_char_id VARCHAR(255), in_class_id VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	DECLARE hit_die_str VARCHAR(255) DEFAULT "";
    DECLARE constitution_modifier_str VARCHAR(255) DEFAULT "";
    
    # Get the hit die of the associated class
    SELECT class_hit_die INTO hit_die_str FROM class WHERE class_id = in_class_id;
    
    # Calculate the HP addition value based on the constitution ability score (ability_id = 3) of the indicated character
    SELECT FLOOR((charabilityscore_value - 10) / 2) 
    INTO constitution_modifier_str 
    FROM characterabilityscore WHERE char_id = in_char_id
									    AND ability_id = 3; 
    
    # Format and return the information
	RETURN CONCAT("1", hit_die_str, " + ", constitution_modifier_str);
END $$
DELIMITER ;

# 3. Yields the ID's and names of all spells that the indicated character for the indicated class level
#    of the indicated class
#    Works by first generating a list of all spells of that minimum class level that can be learned by that class
#    and then filtering this list by the spells that the character has already learned
DROP PROCEDURE IF EXISTS get_learnable_spells_for_character_of_class_at_level;
DELIMITER $$
CREATE PROCEDURE get_learnable_spells_for_character_of_class_at_level(in_char_id VARCHAR(255), in_class_id VARCHAR(255), in_class_level VARCHAR(255))
BEGIN
    # Returns filtered list of unlearned cantrips (indicated by a required in_class_level of 0), as all cantrips can be learned by all classes
	IF in_class_level = 0
    THEN
		SELECT spell_id, spell_name
        FROM spell
        WHERE spell_min_level = 0
              AND spell_id NOT IN ( SELECT spell_id
                                    FROM learnedspell
                                    WHERE char_id = in_char_id
								  );
	# Returns filtered list of spells with indicated level that are class-specific
	ELSE
		SELECT spell_id, spell_name 
		FROM classlearnablespell JOIN spell USING(spell_id) 
		WHERE class_id = in_class_id 
			  AND cls_required_class_level = in_class_level 
		      AND spell_id NOT IN ( SELECT spell_id 
									FROM learnedspell 
									WHERE char_id = in_char_id 
								  );
	END IF;
END $$
DELIMITER ;

# 4. Conditional means of increasing the character's base HP by the indicated amount
#    with safety checks for if the character has NULL (default) values for HP
DROP PROCEDURE IF EXISTS increase_char_base_hp;
DELIMITER $$
CREATE PROCEDURE increase_char_base_hp(in_char_id VARCHAR(255), in_new_hp VARCHAR(255))
BEGIN
	DECLARE old_hp VARCHAR(255) DEFAULT "";
    
    SELECT IFNULL(char_base_hp, 0) 
    INTO old_hp 
    FROM `character` 
    WHERE char_id = in_char_id;
    
    UPDATE `character` 
		   SET char_base_hp = in_new_hp + old_hp 
           WHERE char_id = in_char_id;
END $$
DELIMITER ;

# 5. Returns the number of levels taken by the indicated character in the indicated class
#    Used in determining level up values when a character takes a level in a class
DROP FUNCTION IF EXISTS get_character_class_level;
DELIMITER $$
CREATE FUNCTION get_character_class_level(in_char_id VARCHAR(255), in_class_id VARCHAR(255))
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE class_level INT DEFAULT NULL;
    
    # Gets the sum of all the levels taken by the character in the indicated class
    # with limiting by 1 to provided a safety catch
    SELECT sum(`Levels`) 
    INTO class_level 
    FROM levelallocation_details 
    WHERE ID = in_char_id AND class_id = in_class_id 
    GROUP BY class_id 
    LIMIT 1;
    
    IF class_level IS NULL
    THEN
		RETURN 0;
	ELSE
		RETURN class_level;
	END IF;
END $$
DELIMITER ;

# 6. Used as part of the level up process
#    If character has previously taken a level in the class, increase the corresponding level value in the associative
#    'levelallocation' entity by 1;
#    Otherwise, insert a new record into the levelallocation table for the character with that class with an overall level of 1
#    to indicate that this is the first level they've taken in that class
DROP PROCEDURE IF EXISTS give_character_new_level_allocation;
DELIMITER $$
CREATE PROCEDURE give_character_new_level_allocation(in_char_id VARCHAR(255), in_class_id VARCHAR(255))
BEGIN
	DECLARE old_level_for_class VARCHAR(255) DEFAULT NULL;
    
    SELECT levelallocation_level 
    INTO old_level_for_class 
    FROM levelallocation 
    WHERE class_id = in_class_id 
          AND char_id = in_char_id;
    
    IF old_level_for_class IS NOT NULL
    THEN
		UPDATE levelallocation 
               SET levelallocation_level = old_level_for_class + 1 
               WHERE class_id = in_class_id 
                     AND char_id = in_char_id;
	ELSE
		SET @query = CONCAT("INSERT INTO levelallocation(char_id, class_id, levelallocation_level) VALUES(", in_char_id, ", ", in_class_id, ", 1)");
        PREPARE stmt FROM @query;
        EXECUTE stmt;
        
        DEALLOCATE PREPARE stmt;
	END IF;
END $$
DELIMITER ;

# 7. For the given class at the given level, returns the number of each level of spell
#    that is learned at that new level
DROP PROCEDURE IF EXISTS get_newspells_count_for_class_at_level;
DELIMITER $$
CREATE PROCEDURE get_newspells_count_for_class_at_level(in_class_id VARCHAR(255), in_level VARCHAR(255))
BEGIN
	# If first level, just return the value associated with each level of spell
	IF in_level = 1
		THEN
			SELECT newspellscount_cantrips as "New Cantrips", 
				   newspellscount_spell_slots_level_1 as "New Level 1",
				   newspellscount_spell_slots_level_2 as "New Level 2",
		           newspellscount_spell_slots_level_3 as "New Level 3",
                   newspellscount_spell_slots_level_4 as "New Level 4",
                   newspellscount_spell_slots_level_5 as "New Level 5",
                   newspellscount_spell_slots_level_6 as "New Level 6",
                   newspellscount_spell_slots_level_7 as "New Level 7",
                   newspellscount_spell_slots_level_8 as "New Level 8",
                   newspellscount_spell_slots_level_9 as "New Level 9"
	        FROM classlevelnewspellscount WHERE class_id = in_class_id AND newspellscount_class_level = in_level;
	ELSE
		# If higher level than one, return the difference between the current level and the previous level for each
        # level of spell
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
		FROM classlevelnewspellscount as prev_level JOIN curr_level ON prev_level.class_id = in_class_id 
                                                                    AND prev_level.newspellscount_class_level = (SELECT in_level - 1);
	END IF;
END $$
DELIMITER ;

# 8. Assisted deletion of one or more records in the indicated table with that match(es) the specified in_conditions
#    In the case that the ID of the player attempting to delete the record doesn't match the ID of the creator of the record,
#    the deletion fails.
DROP PROCEDURE IF EXISTS delete_record_in_table;
DELIMITER $$
CREATE PROCEDURE delete_record_in_table(in_table VARCHAR(255), in_dm_id VARCHAR(100), in_conditions TEXT, delete_multi BOOLEAN)
BEGIN
	DECLARE delete_limit_condition VARCHAR(255) DEFAULT "";
    DECLARE order_by_condition VARCHAR(255) DEFAULT "";
    DECLARE creator_condition VARCHAR(255) DEFAULT "";
    
    # If not to delete multiple records, set the delete limit to 1, and use ordering for classes that feature a counter
    IF delete_multi = 0
    THEN
		SET delete_limit_condition = " LIMIT 1";
            IF in_table = "monsterlootitem"
			THEN
				SET order_by_condition = " ORDER BY monsterlootitem_counter DESC";
			ELSEIF in_table = "characterinventoryitem"
			THEN
				SET order_by_condition = " ORDER BY characterinventoryitem_counter DESC";
			END IF;
	END IF;
    
    # Prepare creator_condition to be part of full conditional statement
    IF in_conditions = "" OR in_conditions = " "
    THEN
		SET creator_condition = "WHERE ";
	ELSE
		SET creator_condition = "AND ";
	END IF;
    
    # Build the condition that the entity can only be deleted by the player/dm who created it
    IF in_table = "character" OR in_table = "character_details"
    THEN
		SET creator_condition = CONCAT(creator_condition, "player_id = '", (SELECT player_id FROM dungeonmaster WHERE dm_id = in_dm_id), "'");
	ELSE
		SET creator_condition = CONCAT(creator_condition, "dm_id = '", in_dm_id, "'");
	END IF;
    
    # Build the full delete statement, using the entity, initial conditions, creator condition, any ordering, and any limits
    SET @query = CONCAT("DELETE FROM ", in_table, " ", in_conditions, creator_condition, order_by_condition, delete_limit_condition);
    PREPARE stmt FROM @query;
    EXECUTE stmt;
    
    DEALLOCATE PREPARE stmt;
END $$
DELIMITER ;

# 9. Utility procedure to quickly help DM's determine new monsterparties for their campaign
#    Given the campaign, a range for the challenge rating value, and the number of monsters to include
#    generates a random list of that size of monsters with a challenge rating in that range that
#    have not yet been used in the campaign
DROP PROCEDURE IF EXISTS get_monster_info_for_quick_monsterparty_create;
DELIMITER $$
CREATE PROCEDURE get_monster_info_for_quick_monsterparty_create(in_campaign_id VARCHAR(10), min_cr VARCHAR(10), max_cr VARCHAR(10), party_size INT)
BEGIN
	SELECT monster_id,
           monster_name,
           monster_challenge_rating
    FROM monster
    WHERE monster_challenge_rating >= min_cr
          AND monster_challenge_rating <= max_cr
          AND monster_id NOT IN ( SELECT monster_id 
                                  FROM monsterencounter JOIN monsterparty USING(monsterparty_id)
                                  WHERE campaign_id = in_campaign_id
								)
	ORDER BY RAND()
    LIMIT party_size;
END $$
DELIMITER ;

# 10. Returns all campaigns that player is a member of but does not yet have a character for
#     Used in the webpage to return a list of all campaigns that a player can add the current character to
DROP PROCEDURE IF EXISTS get_open_campaigns_of_player;
DELIMITER $$
CREATE PROCEDURE get_open_campaigns_of_player(in_player_id VARCHAR(255))
BEGIN
	SELECT campaign_id FROM partymember WHERE player_id = in_player_id AND char_id IS NULL;
END $$
DELIMITER ;

# 11. Selects the ID, name, and description of the skills that the character will perform the worst in
#     For the DM's out there with an axe to grind against their players, allows them to determine the
#     situations they can put each of the characters involved in their campaign into to ensure the least 
#     likelihood of success.
DROP PROCEDURE IF EXISTS get_character_worst_skills;
DELIMITER $$
CREATE PROCEDURE get_character_worst_skills(in_char_id VARCHAR(10))
BEGIN
	DECLARE lowest_ability_id TINYINT DEFAULT NULL;
    
    SELECT ability_id 
    INTO lowest_ability_id
	FROM characterabilityscore JOIN `character` USING(char_id)
    WHERE char_id = in_char_id
	ORDER BY charabilityscore_value DESC
    LIMIT 1;
    
    SELECT skill_id, skill_name, skill_description
    FROM skill
    WHERE ability_id = lowest_ability_id;
END $$
DELIMITER ;

# 12. Used extensively, as the core component of the Entity Details page for retrieving display information for both 
#     the in-record field values of the entity, as well as the field values of all associative entities linked to that entity
#     via successive calls.
#     First, for each column of the chosen entity that will be displayed, determines whether or not
#     the indicated player has write privileges for that attribute,
#     as determined by:
#					1. Whether or not tthe entity is a base entity and the attribute is a field directly stored in that entity
#					   that has information isolated within that entity
#					2. The player was the creator of the entity
#     These readonly/write allowed values are then UNION'ed with the appropriate columns from either the
#     view associated with that entity - if it exists - or a selection of the columns of the original entity.
DROP PROCEDURE IF EXISTS get_direct_entity_details;
DELIMITER $$
CREATE PROCEDURE get_direct_entity_details(entity VARCHAR(255), primary_key_value VARCHAR(255), in_player_id INT)
BEGIN
	DECLARE creator_id INT DEFAULT NULL;
	DECLARE allow_edits VARCHAR(255) DEFAULT "NO";
    DECLARE player_dm_id INT DEFAULT NULL;
    SET player_dm_id = (SELECT dm_id FROM dungeonmaster WHERE player_id = in_player_id);

    # Abilities cannot be created by users, so allow_edits is defaulted to "NO"
    IF entity = "ability"
    THEN
		SELECT "NO" as "ID", "NO" as "Ability", "NO" as "Description"
        UNION ALL
		SELECT * FROM ability WHERE ability_id = primary_key_value;
	ELSEIF entity = "campaign"
    THEN
		SET creator_id = (SELECT dm_id FROM campaign WHERE campaign_id = primary_key_value AND dm_id = player_dm_id);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
		END IF;
        SELECT "NO" as "ID", allow_edits as "Name", allow_edits as "Plot", allow_edits as "Setting", allow_edits as "Active", "NO" as "DM", allow_edits as "Party Name"
        UNION ALL
        SELECT * FROM campaign_details WHERE ID = primary_key_value;
	ELSEIF entity = "private_campaign_partymember"
    THEN
		# No setting edits allowed for associative entities
		SELECT "NO" as "ID", "NO" as "Player", "NO" as "Name", "NO" as "Gender", "NO" as "Overall Level", "NO" as "Level Allocation", "NO" as "Race", "NO" as "Speed",
               "NO" as "Size", "NO" as "Backstory", "NO" as "Notes", "NO" as "Base HP", "NO" as "Money", "NO" as "Inventory"
		UNION ALL
		SELECT * FROM private_campaign_partymember_details WHERE ID = primary_key_value;
	ELSEIF entity = "public_campaign_partymember"
    THEN
		# No edits allowed for associative entities
		SELECT "NO" as "ID", "NO" as "Player", "NO" as "Character Name", "NO" as "Class"
		UNION ALL
        SELECT * FROM public_campaign_partymember_details WHERE ID = primary_key_value;
	ELSEIF entity = "character"
    THEN
		SET creator_id = (SELECT player_id FROM `character` WHERE char_id = primary_key_value AND player_id = in_player_id);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
		END IF;
        SELECT "NO" as "ID", allow_edits as "Name", "NO" as "Player", allow_edits as "Gender", "NO" as "Overall Level", "NO" as "Level Allocations", "NO" as "Race", 
               "NO" as "Speed", "NO" as "Size", allow_edits as "Backstory", allow_edits as "Age", allow_edits as "Height", allow_edits as "Notes", allow_edits as "Public Class", 
               allow_edits as "Base HP", allow_edits as "Remaining HP", allow_edits as "Platinum", allow_edits as "Gold", allow_edits as "Silver", allow_edits as "Copper"
		UNION ALL
		SELECT * FROM character_details WHERE ID = primary_key_value;
	ELSEIF entity = "characterabilityscore"
    THEN
    	# Associative entity
        SELECT
				"NO" as "ID", "NO" as "ability_id", "NO" as "Ability", "NO" as "Score"
        UNION ALL
        SELECT * FROM characterabilityscore_details WHERE ID = primary_key_value;
	ELSEIF entity = "characterinventoryitem"
    THEN
		# Associative entity
		SELECT "NO" as "ID", "NO" as "item_id", "NO" as "Item"
        UNION ALL
		SELECT * FROM characterinventoryitem_details WHERE ID = primary_key_value;
	ELSEIF entity = "characterlearnedlanguage"
    THEN
		# Associative entity
		SELECT "NO" as "ID", "NO" as "language_id", "NO" as "Language"
        UNION ALL
        SELECT * FROM characterlearnedlanguage_details WHERE ID = primary_key_value;
	ELSEIF entity = "class"
    THEN
		# Classes cannot be created by users, so all values are readonly
        SELECT "NO"as "ID", "NO" as "Name", "NO" as "Description", "NO" as "Hit Die", "NO" as "Role"
        UNION ALL
        SELECT * FROM class WHERE class_id = primary_key_value;
	ELSEIF entity = "classlearnablespell"
    THEN
		# Associative entity
        SELECT "NO" as "ID", "NO" as "spell_id", "NO" as "Spell", "NO" as "Required Class Level"
        UNION ALL
        SELECT * FROM classlearnablespell_details WHERE ID = primary_key_value;
	ELSEIF entity = "classlevelnewspellcount"
	THEN
		# Associative entity
        SELECT "NO" as "ID", "NO" as "Class", "NO" as "Level", "NO" as "Number of Cantrips", "NO" as "Number of Spells", "NO" as "Level 1 Spells", "NO" as "Level 2 Spells",
               "NO" as "Level 3 Spells", "NO" as "Level 4 Spells", "NO" as "Level 5 Spells", "NO" as "Level 6 Spells", "NO" as "Level 7 Spells", "NO" as "Level 8 Spells",
               "NO" as "Level 9 Spells"
        UNION ALL
        SELECT * FROM classlevelnewspellscount_details WHERE ID = primary_key_value;
	ELSEIF entity = "dungeonmaster"
    THEN
		# Associative entity
        SELECT "NO" as "ID", "NO" as "player_id"
        UNION ALL
		SELECT * FROM dungeonmaster WHERE dm_id = primary_key_value;
	ELSEIF entity = "item"
    THEN
		SET creator_id = (SELECT dm_id FROM item WHERE item_id = primary_key_value AND dm_id = player_dm_id);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
		END IF;
		SELECT "NO" as "ID", allow_edits as "Name", allow_edits as "Description", allow_edits as "Rarity", allow_edits as "Type", allow_edits as "Price", 
                allow_edits as "Requires Attunement", "NO" as "Creator"
		UNION ALL
		SELECT * FROM item_details WHERE ID = primary_key_value;
	ELSEIF entity = "language"
    THEN
		# Languages cannot be created by users, and so are fully readonly
        SELECT "NO" as "ID", "NO" as "Language", "NO" as "Description"
        UNION ALL
		SELECT * FROM `language` WHERE language_id = primary_key_value;
	ELSEIF entity = "learnedspell"
    THEN
		# Associative entity
        SELECT "NO" as "ID", "NO" as "spell_id", "NO" as "Spell"
        UNION ALL
        SELECT * FROM learnedspell_details WHERE ID = primary_key_value;
	ELSEIF entity = "levelallocation"
    THEN
		# Associative entity
        SELECT "NO" as "ID", "NO" as "class_id", "NO" as "Class", "NO" as "Levels"
        UNION ALL
        SELECT * FROM levelallocation_details WHERE ID = primary_key_value;
	ELSEIF entity = "monster"
    THEN
		SET creator_id = (SELECT dm_id FROM monster WHERE monster_id = primary_key_value AND dm_id = player_dm_id LIMIT 1);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
        END IF;
        
		SELECT "NO" as "ID", allow_edits as "Name", allow_edits as "Armor Class", allow_edits as "Challenge Rating", allow_edits as "Description", allow_edits as "Base HP", "NO" as "Creator"
		UNION ALL
        SELECT * FROM monster_details WHERE ID = primary_key_value;
	ELSEIF entity = "monsterabilityscore"
    THEN
		# Associative entity
        SELECT "NO" as "ID", "NO" as "ability_id", "NO" as "Ability", "NO" as "Score"
        UNION ALL
        SELECT * FROM monsterabilityscore_details WHERE ID = primary_key_value;
	ELSEIF entity = "monsterencounter"
    THEN
		SET creator_id = (SELECT dm_id FROM monsterencounter JOIN monsterparty WHERE encounter_id = primary_key_value AND dm_id = player_dm_id);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
		END IF;
        SELECT "NO" as "ID", "NO" as "Monster", allow_edits as "HP Remaining"
        UNION ALL
        SELECT * FROM monsterencounter_details WHERE ID = primary_key_value;
	ELSEIF entity = "monsterparty_monsterencounter"
    THEN
		# Associative view of monsterencounter from within monsterparty => don't allow HP edits to be made from this page
        SELECT "NO" as "ID", "NO" as "encounter_id", "NO" as "Monster Name", "NO" as "HP Remaining", "NO" as "Loot Items"
        UNION ALL
		SELECT * FROM monsterparty_monsterencounter_details WHERE ID = primary_key_value;
	ELSEIF entity = "monsterlootitem"
    THEN
		# Associative entity
		SELECT "NO" as "ID", "NO" as "item_id", "NO" as "Item"
        UNION ALL
        SELECT * FROM monsterlootitem_details WHERE ID = primary_key_value;
	ELSEIF entity = "monsterparty"
    THEN
		SET creator_id = (SELECT dm_id FROM monsterparty WHERE monsterparty_id = primary_key_value AND dm_id = player_dm_id);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
		END IF;
        SELECT "NO" as "ID", allow_edits as "Location", "NO" as "Campaign"
        UNION ALL
		SELECT * FROM monsterparty_details WHERE ID = primary_key_value;
	ELSEIF entity = "player_partymember"
    THEN
		# Associative entity
        SELECT "NO" as "ID", "NO" as "Player", "NO" as "Character Name"
        UNION ALL
        SELECT * FROM player_partymember_details WHERE ID = primary_key_value;
	ELSEIF entity = "character_partymember"
    THEN
		# Associative entity
        SELECT "NO" as "ID", "NO" as "campaign_id", "NO" as "Campaign", "NO" as "DM"
        UNION ALL
        SELECT * FROM character_partymember_details WHERE ID = primary_key_value;
	ELSEIF entity = "player"
    THEN
		SET creator_id = (SELECT dm_id FROM dungeonmaster WHERE player_id = primary_key_value AND dm_id = player_dm_id);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
		END IF;
        SELECT "NO" as "ID", allow_edits as "Nickname"
        UNION ALL
		SELECT * FROM player_details WHERE ID = primary_key_value;
	ELSEIF entity = "race"
    THEN
		SET creator_id = (SELECT dm_id FROM race WHERE race_id = primary_key_value AND dm_id = player_dm_id);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
		END IF;
        SELECT "NO" as "ID", allow_edits as "Name", allow_edits as "Description", allow_edits as "Speed", allow_edits as "Size", "NO" as "Creator ID"
        UNION ALL
		SELECT * FROM race WHERE race_id = primary_key_value;
	ELSEIF entity = "raceabilityscoremodifier"
    THEN
		# Associative entity
        SELECT "NO" as "ID", "NO" as "race_id", "NO" as "Ability", "NO" as "Score"
        UNION ALL
        SELECT * FROM raceabilityscoremodifier_details WHERE ID = primary_key_value;
	ELSEIF entity = "raceknownlanguage"
    THEN
		# Associative entity
        SELECT "NO" as "ID", "NO" as "Race", "NO" as "language_id", "NO" as "Language"
        UNION ALL
        SELECT * FROM raceknownlanguage_details WHERE ID = primary_key_value;
	ELSEIF entity = "schoolofmagic"
    THEN
		# Cannot be created by DMs, so readonly
        SELECT "NO" as "ID", "NO" as "School", "NO" as "Description"
        UNION ALL
		SELECT * FROM schoolofmagic WHERE magicschool_id = primary_key_value;
	ELSEIF entity = "skill"
    THEN
		# Cannot be created by DMs, so readonly
        SELECT "NO" as "ID", "NO" as "Skill", "NO" as "Description", "NO" as "Linked Ability"
        UNION ALL
		SELECT * FROM skill_details WHERE ID = primary_key_value;
	ELSEIF entity = "spell"
    THEN
		SET creator_id = (SELECT dm_id FROM spell WHERE spell_id = primary_key_value AND dm_id = player_dm_id);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
		END IF;
		SELECT "NO" as "ID", allow_edits as "Spell Name", allow_edits as "Description", allow_edits as "Minimum Level", allow_edits as "Range", allow_edits as "Casting Time",
               allow_edits as "Duration", allow_edits as "Is Concentration", allow_edits as "Material Components", "NO" as "School of Magic", "NO" as "Creator ID"
        UNION ALL
		SELECT * FROM spell_details WHERE ID = primary_key_value;
	ELSEIF entity = "weapon"
    THEN
		SET creator_id = (SELECT dm_id FROM weapon JOIN item USING(item_id) WHERE weapon_id = primary_key_value AND dm_id = player_dm_id);
        IF creator_id IS NOT NULL
        THEN
			SET allow_edits = "YES";
		END IF;
		SELECT "NO" as "ID", allow_edits as "Name", allow_edits as "Description", allow_edits as "Rarity", allow_edits as "Type", allow_edits as "Price", allow_edits as "Requires Attunement",
               allow_edits as "Roll", allow_edits as "Damage Mod", allow_edits as "Range", allow_edits as "Damage Type", "NO" as "Creator"
		UNION ALL
        SELECT * FROM weapon_details WHERE ID = primary_key_value;
    END IF;
END $$
DELIMITER ;


-- ------------------------------------------- 3 Required Triggers ------------------------------------------- --

# 1.1 Campaign Delete - Requires 3 nested triggers: Campaign -> Monsterparty -> MonsterEncounter -> LootItem
#	  First deletes all monsterparties and partymember instances associated with the given campaign before deleting the campaign
DROP TRIGGER IF EXISTS delete_campaign_trigger;
DELIMITER $$
CREATE TRIGGER delete_campaign_trigger 
BEFORE DELETE ON campaign 
FOR EACH ROW
BEGIN
	DELETE FROM monsterparty WHERE OLD.campaign_id = monsterparty.campaign_id;
    DELETE FROM partymember WHERE OLD.campaign_id = partymember.campaign_id;
END $$
DELIMITER ;

# 1.2 Monsterparty delete required by Campaign Delete
#	  First deletes all monsterencounters associated with the given monsterparty before deleting the monsterparty
DROP TRIGGER IF EXISTS delete_monster_party_trigger;
DELIMITER $$
CREATE TRIGGER delete_monster_party_trigger 
BEFORE DELETE ON monsterparty 
FOR EACH ROW
BEGIN
	DELETE FROM monsterencounter WHERE OLD.monsterparty_id = monsterencounter.monsterparty_id;
END $$
DELIMITER ;

# 1.3 Monster delete required by Monsterencounter Delete (and Monsterparty, Campaign Deletes)
#	  First deletes all lootitems associated with the given encounter before deleting the encounter
DROP TRIGGER IF EXISTS delete_monster_encounter_trigger;
DELIMITER $$
CREATE TRIGGER delete_monster_encounter_trigger 
BEFORE DELETE ON monsterencounter 
FOR EACH ROW
BEGIN
	DELETE FROM monsterlootitem WHERE OLD.encounter_id = monsterlootitem.encounter_id;
END $$
DELIMITER ;

# 2. When a characterability score is created as part of the character creation process, 
#    modifies the ability score based on the associated ability score modifier (modifier value and target ability) 
#    of the character's race
DROP TRIGGER IF EXISTS apply_race_modifier_to_characterabilityscore;
DELIMITER $$
CREATE TRIGGER apply_race_modifier_to_characterabilityscore
BEFORE
INSERT ON characterabilityscore
FOR EACH ROW
BEGIN
	DECLARE modifier INT DEFAULT 0;
    
    # Save the integer modifier of the character's race for the associated ability
    SELECT racemodifier_value 
    INTO modifier 
    FROM raceabilityscoremodifier JOIN race USING(race_id) 
								  JOIN `character` USING(race_id) 
	WHERE char_id = NEW.char_id 
		  AND ability_id = NEW.ability_id;
	
    # Update the ability score value to be added based on the modifier
    SET NEW.charabilityscore_value = modifier + NEW.charabilityscore_value;
END $$
DELIMITER ;

# 3. When a character is created, adds all languages inherently known
#    by the character's associated race to the list of languages known
#    by the character
DROP TRIGGER IF EXISTS add_race_languages_to_character;
DELIMITER $$
CREATE TRIGGER add_race_languages_to_character
AFTER
INSERT ON `character`
FOR EACH ROW
BEGIN
	# For each language in raceknownlanguage with the associated race of the character
    # insert a new entry into characterlearnedlanguage with the character and language ID's
	INSERT INTO characterlearnedlanguage 
					SELECT NEW.char_id, language_id 
					FROM race JOIN `character` USING(race_id)
							  JOIN raceknownlanguage USING(race_id)
				    WHERE char_id = NEW.char_id;
END $$
DELIMITER ;


-- ------------------------------------------- Miscellaneous Triggers ------------------------------------------- --

# 1. Delete Character Trigger
#    First deletes all associative entity instances associated with the character in a particular order
#	 before finally deleting the Character, to ensure integrity and prevent errors
DROP TRIGGER IF EXISTS delete_character_trigger;
DELIMITER $$
CREATE TRIGGER delete_character_trigger 
BEFORE DELETE ON `character` 
FOR EACH ROW
BEGIN
  DELETE FROM characterabilityscore WHERE 
    characterabilityscore.char_id = old.char_id;

  DELETE FROM characterlearnedlanguage WHERE 
    characterlearnedlanguage.char_id = old.char_id;

  DELETE FROM characterinventoryitem WHERE 
    characterinventoryitem.char_id = old.char_id;

  DELETE FROM learnedspell WHERE 
    learnedspell.char_id = old.char_id;

  DELETE FROM characterabilityscore WHERE 
    characterabilityscore.char_id = old.char_id;

  DELETE FROM levelallocation WHERE 
    levelallocation.char_id = old.char_id;

END $$
DELIMITER ;

# 2. If attempting to add a DM with no associated player, first create a player for that DM, and link the two
#	 In the case where no players exist in the DB yet, assumes that the "DM" is from the import file
#	 and thus is the "Base Game" content
DROP TRIGGER IF EXISTS create_player_for_dm;
DELIMITER $$
CREATE TRIGGER create_player_for_dm
BEFORE INSERT ON dungeonmaster
FOR EACH ROW
BEGIN
	DECLARE player_default_username VARCHAR(32) DEFAULT "default_";
    DECLARE next_player_id INT DEFAULT NULL;
    
	IF NEW.player_id IS NULL
    THEN
		SELECT IFNULL(count(*),0) + 1 INTO next_player_id FROM player;
        IF next_player_id = 1
        THEN
			INSERT INTO player(player_id,player_username,player_nickname,player_password) VALUES(next_player_id,"", "Base Game", "");
		ELSE
			INSERT INTO player(player_id,player_username,player_nickname,player_password) VALUES(next_player_id,CONCAT(player_default_username, next_player_id), "DEFAULT", "");
		END IF;
		SET NEW.player_id = next_player_id;
	END IF;
END $$
DELIMITER ;

# 3. Workaround for MariaDB's prohibition of autoincrement of a subcomponent of a 3 component primary key
#    Increments the counter for the associated item type of the given character
#    in order to allow characters to carry multiples of the same item
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

# 4. Workaround for MariaDB's prohibition of autoincrement of a subcomponent of a 3 component primary key
#    Same format as `characterinventoryitem_autoincrement` trigger above.
#    Increments the counter for the associated item type of the given monsterencounter
#    in order to allow monsterencounters to carry multiples of the same item
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

# 5. Automatically adjusts the in-record "overall level" field of a character on level up
#    This handles the case when the level added is of a class that the character has not yet taken
#    a level in previously
DROP TRIGGER IF EXISTS character_level_autoincrement_on_insert;
DELIMITER $$
CREATE TRIGGER character_level_autoincrement_on_insert
AFTER
INSERT ON levelallocation
FOR EACH ROW
BEGIN
	UPDATE `character` 
		   SET `character`.char_overall_level = `character`.char_overall_level + 1 
	WHERE `character`.char_id = NEW.char_id;
END $$
DELIMITER ;

# 6. Automatically adjusts the in-record "overall level" field of a character on level up
#    This handles the case when the level added is of a class that the character has previously
#    taken a level in
DROP TRIGGER IF EXISTS character_level_autoincrement_on_update;
DELIMITER $$
CREATE TRIGGER character_level_autoincrement_on_update
AFTER
UPDATE ON levelallocation
FOR EACH ROW
BEGIN
	DECLARE total_levels VARCHAR(255) DEFAULT NULL;
    SELECT sum(levelallocation_level) INTO total_levels FROM levelallocation WHERE char_id = NEW.char_id;
	UPDATE `character` 
		   SET `character`.char_overall_level = total_levels
	WHERE `character`.char_id = NEW.char_id;
END $$
DELIMITER ;

# 7. If player provides no nickname, default it to the username
#    Used in the "sign up" page, to allow the "nickname" field to be optional
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


-- ------------------------------------------- Miscellaneous Functions & Procedures ------------------------------------------- --

# 1. Returns the attribute name and data type of all non-foreign key attributes of a given table
DROP PROCEDURE IF EXISTS get_non_foreign_key_column_names_and_datatypes;
DELIMITER $$
CREATE PROCEDURE get_non_foreign_key_column_names_and_datatypes(IN entity VARCHAR(255))
BEGIN
	DECLARE modified_entity_name VARCHAR(255) DEFAULT "";
    
    # If input entity is a special variant of a view that doesn't exist, default to returning
    # data for the base table
    IF entity IN ("ability_details", "class_details", "campaign_details", "dungeonmaster_details", "item_details",
				  "language_details", "player_details", "race_details", "schoolofmagic_details"
				 )
	THEN
		SET modified_entity_name = SUBSTRING_INDEX(entity, "_details", 1);
	ELSE
		SET modified_entity_name = entity;
	END IF;
    
	SELECT column_name, 
           column_type
	FROM INFORMATION_SCHEMA.columns
	WHERE table_schema="csuciklo_COMP420_DnDB"
		  AND table_name = modified_entity_name
		  AND column_key != "MUL";
END $$
DELIMITER ;

# 2. Returns select statement used to retrieve the names of the foreign keys within a given entity and the tables they link to
DROP FUNCTION IF EXISTS get_select_for_foreign_key_columns_and_referenced_table_names;
DELIMITER $$
CREATE FUNCTION get_select_for_foreign_key_columns_and_referenced_table_names(entity VARCHAR(255))
RETURNS TEXT
DETERMINISTIC
BEGIN
	RETURN CONCAT("SELECT column_name, referenced_table_name FROM INFORMATION_SCHEMA.key_column_usage WHERE table_schema = 'csuciklo_COMP420_DnDB' AND table_name = '", entity, "' AND referenced_table_name IS NOT NULL");
END $$
DELIMITER ;

# 3. Makes use of function above to retrieve the names of the foreign keys within a given entity and the tables they link to 
DROP PROCEDURE IF EXISTS get_foreign_key_column_names_and_referenced_table_names;
DELIMITER $$
CREATE PROCEDURE get_foreign_key_column_names_and_referenced_table_names(IN entity VARCHAR(255))
BEGIN
	SET @query = "";
    SELECT get_select_for_foreign_key_columns_and_referenced_table_names(entity) INTO @query;
    PREPARE stmt FROM @query;
    EXECUTE stmt;
END $$
DELIMITER ;

# 4. Helper function - Gets the name of the attribute used to generate the "display name" of a given entity
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

# 5. Helper function - Returns a string that can be used in a select to retrieve the actual display value and the name of the attribute used 
#    to generate the "display name" of a given entity
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

# 6. If calling user is the owner of the campaign, indicates that the user should view the "private",
#    fully detailed view of the campaign;
#    Otherwise, only the public view of the campaign should be returned
DROP FUNCTION IF EXISTS get_view_to_call_for_campaign_request;
DELIMITER $$
CREATE FUNCTION get_view_to_call_for_campaign_request(in_dm_id VARCHAR(255), in_campaign_id VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	IF (SELECT dm_id FROM campaign WHERE campaign_id = in_campaign_id LIMIT 1) = in_dm_id
    THEN
		RETURN "private_campaign_partymember";
	ELSE
		RETURN "public_campaign_partymember";
	END IF;
END $$
DELIMITER ;

# 7. Returns a nicely formatted version of the DM's information
DROP FUNCTION IF EXISTS get_dm_display_name;
DELIMITER $$
CREATE FUNCTION get_dm_display_name(in_dm_id VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	DECLARE display_name VARCHAR(255) DEFAULT NULL;
	SELECT CONCAT(`Nickname`, ' (', `Username`, ')') INTO display_name FROM dungeonmaster_details WHERE ID = in_dm_id LIMIT 1;
    RETURN display_name;
END $$
DELIMITER ;

# 8. Given a table, returns the name of the primary key for that table
#    Intended only to be used with non-associative tables
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

# 9. Helper function - builds on get_display_name, to allow for building of more complex statement
#    that only uses the retrieval of the display name of the given table as a subcomponent
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

# 10. Helper function - builds on get_display_and_column_names, to allow for building of more complex statement
#     that only uses the retrieval of the display name value and its associated column name of the given table as a subcomponent
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

# 11. Helper function - used in generating labels for attributes in a web page
DROP PROCEDURE IF EXISTS get_all_column_names_and_datatypes;
DELIMITER $$
CREATE PROCEDURE get_all_column_names_and_datatypes(in_table_name VARCHAR(255))
BEGIN
	DECLARE modified_table_name VARCHAR(255) DEFAULT "";
    IF in_table_name IN ("ability_details", "class_details", "campaign_details", "dungeonmaster_details", "item_details",
				  "language_details", "player_details", "race_details", "schoolofmagic_details"
				 )
	THEN
		SET modified_table_name = SUBSTRING_INDEX(in_table_name, "_details", 1);
	ELSE
		SET modified_table_name = in_table_name;
	END IF;
    
	SELECT column_name, column_type
	FROM INFORMATION_SCHEMA.columns
-- 	WHERE table_schema="csuciklo_dndb"
	WHERE table_schema="csuciklo_COMP420_DnDB"
		  AND table_name = modified_table_name;
END $$
DELIMITER ;

# 12. Helper function - if player has an associated dm_id, returns True; otherwise, returns False
DROP FUNCTION IF EXISTS player_is_dm;
DELIMITER $$
CREATE FUNCTION player_is_dm(in_username VARCHAR(255))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
	RETURN get_dm_id_for_player(in_username) IS NOT NULL;
END $$
DELIMITER ;

# 13. Helper function - returns the dm_id of the associated player, based on the username provided
DROP FUNCTION IF EXISTS get_dm_id_for_player;
DELIMITER $$
CREATE FUNCTION get_dm_id_for_player(in_username VARCHAR(255))
RETURNS INT(10)
DETERMINISTIC
BEGIN
	RETURN ( SELECT dm_id FROM dungeonmaster 
                          JOIN player USING(player_id) 
                          WHERE player_username = in_username 
			 LIMIT 1
            );
END $$
DELIMITER ;

# 14. Helper function - returns the id of the player with the indicated username
DROP FUNCTION IF EXISTS get_player_id_from_username;
DELIMITER $$
CREATE FUNCTION get_player_id_from_username(in_username VARCHAR(255))
RETURNS INT(10)
DETERMINISTIC
BEGIN
	RETURN (SELECT player_id FROM player WHERE player_username = in_username LIMIT 1);
END $$
DELIMITER ;

# 15. Helper function - returns the select statement used to generate the preview of the indicated entity
#     Left as a select statement here to allow for more complex/dynamic filtering and conditions to be applied
#     Returns a row containing the column names followed by the actual retrieved records
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
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'item.item_id' as 'item.item_id', 'Name' as 'Name', 'Rarity' as 'Rarity', 'Type' as 'Type' UNION SELECT 'item.item_id' as 'identifier', 'item' as 'entity', item.item_id as 'item.item_id', item_name as 'Name', item_rarity as 'Rarity', item_type as 'Type' FROM item LEFT JOIN weapon USING(item_id)";
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
    ELSEIF entity = "schoolofmagic"
	THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'magicschool_id' as 'magicschool_id', 'Name' as 'Name' UNION SELECT 'magicschool_id' as 'identifier', 'schoolofmagic' as 'entity', magicschool_id as 'magicschool_id', magicschool_name as 'Name' FROM schoolofmagic";
    ELSEIF entity = "ability"
    THEN
		SET select_stmt = "SELECT 'identifier' as 'identifier', 'entity' as 'entity', 'ability_id' as 'ability_id', 'Ability Name' as 'Ability Name' UNION SELECT 'ability_id' as 'identifier', 'ability' as 'entity', ability_id as 'ability_id', ability_name as 'Ability Name' FROM ability";
    ELSE
		SET select_stmt = CONCAT("SELECT * FROM ", entity);
	END IF;
    
    RETURN select_stmt;
END $$
DELIMITER ;

# 16. Helper function - returns the name of the primary key for the indicated table
#     Not for use with associative entities
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
--     WHERE table_schema="csuciklo_dndb" 
    WHERE table_schema="csuciklo_COMP420_DnDB" 
		  AND table_name = in_table_name 
          AND column_key = "PRI"
	LIMIT 1;
          
	RETURN primary_key_name;
END $$
DELIMITER ;

# 17. Helper function - returns all primary keys from the indicated table that fulfill the given condition
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

# 18. Makes use of the get_select_for_entity_previews helper function to return
#     all previews for the indicated entity that fulfill the given condition
#     Used in the Search and My Creations web pages
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

# 19. Special instance of the get_previews procedure specifically for use in My Campaigns
#     to retrieve both campaigns the player is a member of or the DM of
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

# 20. Helper function - Returns the value of the display name, the statement used to generate the display name, 
#     the value of the foreign key, and the name of the foreign key
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

# 21. Utilizes get_comma_separated_displayname_displaycolname_fkvalue_fkcolname to retrieve the
#     display name value, statement used to generate the display name, foreign key value associated with that display name, and the name of that foreign key
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

# 22 Builds on the functionality of "get_displayname_displaycolname_fkvalue_fkcolname" by adding the condition
#    of retrieving only records from the associated entity that where created by the indicated player
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

# 23. Returns the display name, select statement used to generate the display name, foreign key value associated with that display name, 
#     and the name of the foreign key column for all campaigns that the indicated player is a player in
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

# 24. Retrieves all records of the indicated entity created by the indicated player
DROP PROCEDURE IF EXISTS get_created_records_for_entity;
DELIMITER $$
CREATE PROCEDURE get_created_records_for_entity(in_player_username VARCHAR(255), entity VARCHAR(255))
BEGIN
    DECLARE in_dm_id INT(10);
    DECLARE entity_id_name VARCHAR(255);
    
    IF entity = 'character'
    THEN
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

# 25. Returns just the previews of records of the indicated entity created by the indicated player
DROP PROCEDURE IF EXISTS get_previews_for_entity_created_by_player;
DELIMITER $$
CREATE PROCEDURE get_previews_for_entity_created_by_player(in_username VARCHAR(255), in_entity VARCHAR(255))
BEGIN
	DECLARE in_dm_id INT(10);
    DECLARE entity_id_name VARCHAR(255);
    DECLARE search_condition TEXT DEFAULT "";
    
    IF in_entity = 'character'
    THEN
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

# 26. For use in field updation via the Entity Details page in the web application
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

# 27. Helper function - returns the select statement used to retrieve information about tables linked to the indicated base table via an associative table
#     For each associative table linked to the base entity, returns the associated table name, the name of the table linked to the
#     base entity through the associative table, and the name of the column that is a foreign key in the associative table that refers to the linked table 
DROP FUNCTION IF EXISTS get_select_stmt_for_all_associated_table_and_fkcol_names;
DELIMITER $$
CREATE FUNCTION get_select_stmt_for_all_associated_table_and_fkcol_names(in_table VARCHAR(255))
RETURNS TEXT
DETERMINISTIC
BEGIN
IF in_table = 'monsterparty'
     THEN
 		RETURN CONCAT("SELECT DISTINCT key_cols.table_name as 'table_name', key_cols.table_name as 'referenced_table_name', cols.column_name as 'referenced_column_name' FROM INFORMATION_SCHEMA.key_column_usage as key_cols JOIN INFORMATION_SCHEMA.columns as cols USING(table_name) WHERE key_cols.table_schema = 'csuciklo_COMP420_DnDB' AND key_cols.referenced_table_name = '", in_table, "' AND column_key = 'PRI'");
 	ELSE
		RETURN CONCAT("SELECT table_name, referenced_table_name, referenced_column_name FROM INFORMATION_SCHEMA.key_column_usage WHERE table_schema='csuciklo_COMP420_DnDB' AND table_name IN (SELECT table_name FROM INFORMATION_SCHEMA.key_column_usage WHERE table_schema='csuciklo_COMP420_DnDB' AND referenced_table_name = '", in_table, "') AND REFERENCED_TABLE_NAME IS NOT NULL AND REFERENCED_TABLE_NAME != '", in_table, "'");
 	END IF;
END $$
DELIMITER ;

# 28. Uses the associated helper select statement generator to return the associative table name, linked table name, and foreign key name in the associative table
#     for all associative tables linked to the indicated entity
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

# 29. Uses the associated helper select statement generator to return the associative table name, linked table name, and foreign key name in the associative table
#     for all associative tables linked to the indicated entity filtered with the condition provided
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

# 30. Uses the associated helper select statement generator to return the associative table name, linked table name, and foreign key name in the associative table
#     of a specially filtered selection of the associative tables linked to the given entity
#     The associative tables returned are those that users are allowed to add new instances of
DROP PROCEDURE IF EXISTS get_associated_table_and_fkcol_names_for_create;
DELIMITER $$
CREATE PROCEDURE get_associated_table_and_fkcol_names_for_create(in_table VARCHAR(255))
BEGIN
	DECLARE select_condition TEXT DEFAULT "";
    IF in_table = 'ability'
    THEN
		SET select_condition = "AND table_name != 'characterabilityscore' AND table_name != 'monsterabilityscore' AND table_name != 'raceabilityscoremodifier'";
    ELSEIF in_table = 'campaign'
    THEN
		SET select_condition = "AND table_name != 'dungeonmaster' AND table_name != 'monsterparty' AND table_name != 'monster' AND referenced_table_name != 'character'";
	ELSEIF in_table = 'character'
    THEN
		SET select_condition = "AND referenced_table_name != 'player' AND referenced_table_name != 'class'";
    ELSEIF in_table = 'class'
    THEN
		SET select_condition = "AND table_name != 'levelallocation' AND table_name != 'classlearnablespell'";
	ELSEIF in_table = 'item'
    THEN
		SET select_condition = "AND table_name != 'monsterlootitem' AND table_name != 'characterinventoryitem' AND table_name != 'weapon'";
	ELSEIF in_table = 'language'
    THEN
		SET select_condition = "AND table_name != 'characterlearnedlanguage' AND table_name != 'raceknownlanguage'";
	ELSEIF in_table = 'monster'
    THEN
		SET select_condition = "AND table_name != 'monsterencounter'";
    ELSEIF in_table = 'race'
    THEN 
		SET select_condition = "AND table_name != 'character'";
	ELSEIF in_table = 'spell'
    THEN
		SET select_condition = "AND table_name != 'learnedspell' AND table_name != 'classlearnablespell'";
	ELSEIF in_table = 'schoolofmagic'
    THEN
		SET select_condition = "AND table_name != 'spell'";
	END IF;
    CALL get_associated_table_and_fkcol_names_using_condition(in_table, select_condition);
END $$
DELIMITER ;

# 31. Helper function
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

# 32. Assisted create record procedure used by web application
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
	ELSEIF in_table = "monsterabilityscore"
    THEN
		SET in_col_addition = ",monsterabilityscore_value";
	END IF;
    
    SET @query = CONCAT("INSERT INTO ", usable_tbl_name, "(", in_col_list, in_col_addition, ") VALUES(", in_values, ")");
    PREPARE stmt FROM @query;
    EXECUTE stmt;
END $$
DELIMITER ;

# 33.  Used as a preliminary step in deleting associative records linked to a particular base entity
#      Given the associative table and the name of the foreign key that links that associative table to the main base entity,
#      returns the name of the other foreign key in the table
DROP FUNCTION IF EXISTS get_other_id_colname_from_associative;
DELIMITER $$
CREATE FUNCTION get_other_id_colname_from_associative(in_table VARCHAR(255), in_id_colname VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	RETURN ( SELECT column_name
		     FROM INFORMATION_SCHEMA.columns 
             WHERE table_schema="csuciklo_COMP420_DnDB" 
				   AND table_name = in_table
                   AND column_key = "PRI"
                   AND RIGHT(column_name, 3) = "_id"
				   AND column_name != in_id_colname
			 LIMIT 1
			);
END $$
DELIMITER ;
                                    
-- ------------------------------------------- Miscellaneous Views ------------------------------------------- --

# 1.
DROP VIEW IF EXISTS campaign_details;	
CREATE VIEW campaign_details	
AS	
    SELECT campaign_id as "ID",	
		   campaign_name as "Name", 	
		   campaign_plot_description as "Plot",	
		   campaign_setting_description as "Setting",	
		   campaign_is_active as "Active",	
		   player_nickname as "DM",	
		   campaign_party_name as "Party Name"	
    FROM campaign LEFT JOIN dungeonmaster USING(dm_id)	
				  LEFT JOIN player USING (player_id);
				
# 2.
DROP VIEW IF EXISTS characterabilityscore_details;
CREATE VIEW characterabilityscore_details
AS
    SELECT char_id as "ID",	
		   ability_id as "ability_id",	
		   ability_name as "Ability",	
		   charabilityscore_value as "Score"	
    FROM characterabilityscore left join ability using(ability_id)	
							   left join `character` using (char_id);
							
# 3.
DROP VIEW IF EXISTS characterinventoryitem_details;	
CREATE VIEW characterinventoryitem_details	
AS	
    SELECT char_id as "ID",	
		   item_id,	
		   item_name as "Item"	
    FROM characterinventoryitem left join `character` using (char_id) 	
								left join item using(item_id);

# 4.                                
DROP VIEW IF EXISTS characterlearnedlanguage_details;	
CREATE VIEW characterlearnedlanguage_details	
AS	
    SELECT char_id as "ID",	
		   language_id as "language_id",	
		   language_name as "Language"	
    FROM characterlearnedlanguage left join `character` using(char_id)	
							      left join `language` using (language_id);
# 5.
DROP VIEW IF EXISTS classlearnablespell_details;	
CREATE VIEW classlearnablespell_details	
AS	
    SELECT class_id as "ID",
           spell_id,	
		   spell_name as "Spell",	
		   cls_required_class_level as "Required Level"	
    FROM classlearnablespell left join spell using (spell_id);

# 6.    
DROP VIEW IF EXISTS classlevelnewspellscount_details;	
CREATE VIEW classlevelnewspellscount_details	
AS	
    SELECT class_id as "ID",	
		   class_name as "Class",	
		   newspellscount_class_level as "Level",	
		   newspellscount_cantrips as "Cantrips",	
		   newspellscount_spells as "Spells",	
		   newspellscount_spell_slots_level_1 as "Spell Slot Level 1",	
		   newspellscount_spell_slots_level_2 as "Spell Slot Level 2",	
		   newspellscount_spell_slots_level_3 as "Spell Slot Level 3",	
		   newspellscount_spell_slots_level_4 as "Spell Slot Level 4",	
		   newspellscount_spell_slots_level_5 as "Spell Slot Level 5",	
		   newspellscount_spell_slots_level_6 as "Spell Slot Level 6",	
		   newspellscount_spell_slots_level_7 as "Spell Slot Level 7",	
		   newspellscount_spell_slots_level_8 as "Spell Slot Level 8",	
		   newspellscount_spell_slots_level_9 as "Spell Slot Level 9"	
	FROM classlevelnewspellscount left join class using (class_id);

# 7.
DROP VIEW IF EXISTS dungeonmaster_details;	
CREATE VIEW dungeonmaster_details	
AS	
    SELECT dm_id as "ID",
		   player_id as "player_id",
           player_username as "Username",
		   player_nickname as "Nickname",
           CONCAT(player_nickname, ' (', player_username, ')') as "Display Name"
    FROM dungeonmaster LEFT JOIN player USING (player_id);

# 8.    
DROP VIEW IF EXISTS item_details;	
CREATE VIEW item_details	
AS	
    SELECT item_id as "ID",
		   item_name as "Name",	
		   item_description  as "Description",	
		   item_rarity as "Rarity",	
		   item_type  as "Type",	
		   item_price as "Price",	
		   item_requires_attunement as "Requires Attunement",
           CONCAT(player_nickname, ' (', player_username, ')') as "Creator"
    FROM item LEFT JOIN dungeonmaster USING(dm_id)
              LEFT JOIN player USING(player_id);

# 9.
DROP VIEW IF EXISTS learnedspell_details;	
CREATE VIEW learnedspell_details	
AS	
    SELECT char_id as "ID",	
		   spell_id,	
		   spell_name as "Spell"	
    FROM learnedspell JOIN spell USING (spell_id);
 
# 10. 
DROP VIEW IF EXISTS levelallocation_details;
CREATE VIEW levelallocation_details
AS
    SELECT char_id as "ID",
		   class_id as "class_id",
		   class_name as "Class Name",
           levelallocation_level as "Levels"
    FROM levelallocation JOIN class USING(class_id);

# 11.
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

# 12.                 
DROP VIEW IF EXISTS monsterabilityscore_details;
CREATE VIEW monsterabilityscore_details	
AS	
    SELECT monster_id as "ID",	
		   ability_id,	
		   ability_name as "Ability",	
           monsterabilityscore_value as "Score"	
    FROM monsterabilityscore left join ability using(ability_id)	
							 left join monster using (monster_id);

# 13.                             
DROP VIEW IF EXISTS monsterencounter_details;
CREATE VIEW monsterencounter_details
AS
    SELECT encounter_id as "ID",
		   monster_name as "Monster Name",
           encounter_hp_remaining as "HP Remaining"
    FROM monsterencounter JOIN monster USING(monster_id);

# 14.    
DROP VIEW IF EXISTS monsterlootitem_details;	
CREATE VIEW monsterlootitem_details	
AS	
    SELECT encounter_id as "ID",	
		   item_id,	
		   item_name as "Item"	
    FROM monsterlootitem left join item using (item_id)	
						 left join monsterencounter using (encounter_id);

# 15.
DROP VIEW IF EXISTS monsterparty_details;
CREATE VIEW monsterparty_details
AS
    SELECT monsterparty_id as "ID",
		   monsterparty_location as "Location",
           campaign_name as "Campaign"
    FROM monsterparty JOIN campaign USING(campaign_id);

# 16.
# View of Partymember important details from perspective of a Character (ie. Campaign info)
DROP VIEW IF EXISTS character_partymember_details;
CREATE VIEW character_partymember_details
AS
    SELECT char_id as "ID",
           campaign_id,
	       campaign_name as "Campaign",
           CONCAT(player_nickname, ' (', player_username, ')') as "DM"
    FROM partymember JOIN campaign USING (campaign_id)
		             JOIN dungeonmaster USING(dm_id)
                     JOIN player ON dungeonmaster.player_id = player.player_id;

# 17.
# View of Partymember important details from the perspective of a Campaign (ie. Player & Character info)
DROP VIEW IF EXISTS player_partymember_details;
CREATE VIEW player_partymember_details
AS
    SELECT campaign_id as "ID",
		   player_nickname as "Player",
           char_name as "Character Name"
    FROM partymember JOIN player USING(player_id) LEFT JOIN `character` USING(char_id);

# 18.    
DROP VIEW IF EXISTS player_details;
CREATE VIEW player_details
AS
	SELECT player_id as "ID",
		   player_nickname as "Nickname"
	FROM player;

# 19.    
DROP VIEW IF EXISTS raceabilityscoremodifier_details;	
CREATE VIEW raceabilityscoremodifier_details	
AS	
    SELECT race_id as "ID",
		   ability_id,	
		   ability_name as "Ability",	
           racemodifier_value as "Score"	
    FROM raceabilityscoremodifier JOIN ability USING(ability_id);

# 20.    
DROP VIEW IF EXISTS raceknownlanguage_details;	
CREATE VIEW raceknownlanguage_details	
AS	
    SELECT race_id as "ID",	
		   race_name as "Race",	
		   language_id,	
		   language_name as "Language"	
    FROM raceknownlanguage left join race using(race_id)	
						   left join `language` using (language_id);

# 21.    
DROP VIEW IF EXISTS skill_details;	
CREATE VIEW skill_details	
AS	
    SELECT skill_id as "ID",
		   skill_name as "Skill",	
		   skill_description as "Description",	
		   ability_name as "Ability"	
    FROM skill left join ability using(ability_id);

# 22.    
DROP VIEW IF EXISTS spell_details;	
CREATE VIEW spell_details	
AS	
    SELECT spell_id as "ID",
		   spell_name as "Spell",	
		   spell_description as "Description",	
		   spell_min_level as "Min Level",	
		   spell_range as "Range",	
		   spell_casting_time as "Cast Time",	
		   spell_duration as "Duration",	
		   spell_is_concentration as "Concentration",	
           spell_material as "Material Components",
		   magicschool_name as "School of Magic",
           CONCAT(player_nickname, ' (', player_username, ')') as "Creator"
	FROM spell LEFT JOIN schoolofmagic using(magicschool_id)
               LEFT JOIN dungeonmaster USING(dm_id)
               LEFT JOIN player USING(player_id);