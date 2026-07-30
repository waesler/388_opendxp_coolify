-- --------------------------------------------------------
-- Host:                         128.140.126.141
-- Server-Version:               11.8.8-MariaDB-ubu2404 - mariadb.org binary distribution
-- Server-Betriebssystem:        debian-linux-gnu
-- HeidiSQL Version:             12.10.0.7000
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Exportiere Struktur von Tabelle shopware.users
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `parentId` int(11) unsigned DEFAULT NULL,
  `type` enum('user','userfolder','role','rolefolder') NOT NULL DEFAULT 'user',
  `name` varchar(50) DEFAULT NULL,
  `password` varchar(190) DEFAULT NULL,
  `firstname` varchar(255) DEFAULT NULL,
  `lastname` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `language` varchar(10) DEFAULT NULL,
  `contentLanguages` longtext DEFAULT NULL,
  `admin` tinyint(1) unsigned DEFAULT 0,
  `active` tinyint(1) unsigned DEFAULT 1,
  `permissions` text DEFAULT NULL,
  `roles` varchar(1000) DEFAULT NULL,
  `welcomescreen` tinyint(1) DEFAULT NULL,
  `closeWarning` tinyint(1) DEFAULT NULL,
  `memorizeTabs` tinyint(1) DEFAULT NULL,
  `allowDirtyClose` tinyint(1) unsigned DEFAULT 1,
  `docTypes` text DEFAULT NULL,
  `classes` text DEFAULT NULL,
  `twoFactorAuthentication` varchar(255) DEFAULT NULL,
  `provider` varchar(255) DEFAULT NULL,
  `activePerspective` varchar(255) DEFAULT NULL,
  `perspectives` longtext DEFAULT NULL,
  `websiteTranslationLanguagesEdit` longtext DEFAULT NULL,
  `websiteTranslationLanguagesView` longtext DEFAULT NULL,
  `lastLogin` int(11) unsigned DEFAULT NULL,
  `keyBindings` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`keyBindings`)),
  `isStudio` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `type_name` (`type`,`name`),
  KEY `parentId` (`parentId`),
  KEY `name` (`name`),
  KEY `password` (`password`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Exportiere Daten aus Tabelle shopware.users: ~3 rows (ungefähr)
INSERT INTO `users` (`id`, `parentId`, `type`, `name`, `password`, `firstname`, `lastname`, `email`, `language`, `contentLanguages`, `admin`, `active`, `permissions`, `roles`, `welcomescreen`, `closeWarning`, `memorizeTabs`, `allowDirtyClose`, `docTypes`, `classes`, `twoFactorAuthentication`, `provider`, `activePerspective`, `perspectives`, `websiteTranslationLanguagesEdit`, `websiteTranslationLanguagesView`, `lastLogin`, `keyBindings`, `isStudio`) VALUES
	(0, 0, 'user', 'system', NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0),
	(2, 0, 'user', 'uniadmin', '$2y$10$Zcs4L9NV/Ijy2Ek7jR.JbO6QBlLQWshWkBVbzVuTx0gEzd4rIHHXy', '', '', '', 'de', 'de,en,fr', 1, 1, 'admin_translations,application_logging,assets,asset_metadata,classes,classificationstore,clear_cache,clear_fullpage_cache,clear_temp_files,dashboards,documents,document_types,emails,fieldcollections,gdpr_data_extractor,notes_events,notifications,notifications_send,objectbricks,objects,objects_sort_method,plugin_datahub_adapter_dataImporterDataObject,plugin_datahub_adapter_graphql,plugin_datahub_admin,plugin_datahub_config,predefined_properties,quantityValueUnits,recyclebin,redirects,routes,seemode,share_configurations,sites,system_appearance_settings,system_settings,tags_assignment,tags_configuration,tags_search,thumbnails,translations,users,web2print_settings,website_settings,workflow_details', '', 0, 1, 1, 0, '', '', '{"required":false,"enabled":false,"secret":"","type":""}', NULL, 'default', '', '', '', 1785418272, '[{"key":83,"action":"save","ctrl":true,"alt":false,"shift":false},{"key":80,"action":"publish","ctrl":true,"shift":true,"alt":false},{"key":85,"action":"unpublish","ctrl":true,"shift":true,"alt":false},{"key":82,"action":"rename","alt":true,"shift":true,"ctrl":false},{"key":116,"action":"refresh","alt":false,"ctrl":false,"shift":false},{"key":68,"action":"openDocument","ctrl":true,"shift":true,"alt":false},{"key":65,"action":"openAsset","ctrl":true,"shift":true,"alt":false},{"key":79,"action":"openObject","ctrl":true,"shift":true,"alt":false},{"key":67,"action":"openClassEditor","ctrl":true,"shift":true,"alt":false},{"key":76,"action":"openInTree","ctrl":true,"shift":true,"alt":false},{"key":73,"action":"showMetaInfo","alt":true,"ctrl":false,"shift":false},{"key":87,"action":"searchDocument","alt":true,"ctrl":false,"shift":false},{"key":65,"action":"searchAsset","alt":true,"ctrl":false,"shift":false},{"key":79,"action":"searchObject","alt":true,"ctrl":false,"shift":false},{"key":72,"action":"showElementHistory","alt":true,"ctrl":false,"shift":false},{"key":84,"action":"closeAllTabs","alt":true,"ctrl":false,"shift":false},{"key":83,"action":"searchAndReplaceAssignments","alt":true,"ctrl":false,"shift":false},{"key":82,"action":"redirects","ctrl":false,"alt":true,"shift":false},{"key":84,"action":"sharedTranslations","ctrl":true,"alt":true,"shift":false},{"key":82,"action":"recycleBin","ctrl":true,"alt":true,"shift":false},{"key":78,"action":"notesEvents","ctrl":true,"alt":true,"shift":false},{"key":72,"action":"tagManager","ctrl":true,"alt":true,"shift":false},{"key":78,"action":"tagConfiguration","ctrl":true,"alt":true,"shift":false},{"key":85,"action":"users","ctrl":true,"alt":true,"shift":false},{"key":80,"action":"roles","ctrl":true,"alt":true,"shift":false},{"key":81,"action":"clearAllCaches","ctrl":false,"alt":true,"shift":false},{"key":67,"action":"clearDataCache","ctrl":false,"alt":true,"shift":false},{"key":76,"action":"applicationLogger","ctrl":true,"alt":true,"shift":false},{"key":70,"action":"quickSearch","ctrl":true,"shift":true,"alt":false}]', 0),
	(3, 0, 'user', '1808wurst', '$2y$10$rAQINNpfxpCQ7yiN/0goQe0ZGBsG3FQ5UKGvOssisV0uq.vN2Iuem', '', '', '', 'de', 'de,en,fr', 0, 1, 'assets,objects', '', 0, 1, 1, 0, '', '7', '{"required":false,"enabled":false,"secret":"","type":""}', NULL, NULL, '', '', '', NULL, '[{"key":83,"action":"save","ctrl":true,"alt":false,"shift":false},{"key":80,"action":"publish","ctrl":true,"shift":true,"alt":false},{"key":85,"action":"unpublish","ctrl":true,"shift":true,"alt":false},{"key":82,"action":"rename","alt":true,"shift":true,"ctrl":false},{"key":116,"action":"refresh","alt":false,"ctrl":false,"shift":false},{"key":68,"action":"openDocument","ctrl":true,"shift":true,"alt":false},{"key":65,"action":"openAsset","ctrl":true,"shift":true,"alt":false},{"key":79,"action":"openObject","ctrl":true,"shift":true,"alt":false},{"key":67,"action":"openClassEditor","ctrl":true,"shift":true,"alt":false},{"key":76,"action":"openInTree","ctrl":true,"shift":true,"alt":false},{"key":73,"action":"showMetaInfo","alt":true,"ctrl":false,"shift":false},{"key":87,"action":"searchDocument","alt":true,"ctrl":false,"shift":false},{"key":65,"action":"searchAsset","alt":true,"ctrl":false,"shift":false},{"key":79,"action":"searchObject","alt":true,"ctrl":false,"shift":false},{"key":72,"action":"showElementHistory","alt":true,"ctrl":false,"shift":false},{"key":84,"action":"closeAllTabs","alt":true,"ctrl":false,"shift":false},{"key":83,"action":"searchAndReplaceAssignments","alt":true,"ctrl":false,"shift":false},{"key":82,"action":"redirects","ctrl":false,"alt":true,"shift":false},{"key":84,"action":"sharedTranslations","ctrl":true,"alt":true,"shift":false},{"key":82,"action":"recycleBin","ctrl":true,"alt":true,"shift":false},{"key":78,"action":"notesEvents","ctrl":true,"alt":true,"shift":false},{"key":72,"action":"tagManager","ctrl":true,"alt":true,"shift":false},{"key":78,"action":"tagConfiguration","ctrl":true,"alt":true,"shift":false},{"key":85,"action":"users","ctrl":true,"alt":true,"shift":false},{"key":80,"action":"roles","ctrl":true,"alt":true,"shift":false},{"key":81,"action":"clearAllCaches","ctrl":false,"alt":true,"shift":false},{"key":67,"action":"clearDataCache","ctrl":false,"alt":true,"shift":false},{"key":76,"action":"applicationLogger","ctrl":true,"alt":true,"shift":false},{"key":70,"action":"quickSearch","ctrl":true,"shift":true,"alt":false}]', 0);

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
