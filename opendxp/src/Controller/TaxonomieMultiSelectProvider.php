<?php

namespace App\Controller;

use \OpenDxp\Model\DataObject;
use OpenDxp\Model\DataObject\Taxonomie;
use OpenDxp\Model\DataObject\Taxonomie\Listing;
use OpenDxp\Model\DataObject\ClassDefinition\Data;
use OpenDxp\Model\DataObject\ClassDefinition\DynamicOptionsProvider\SelectOptionsProviderInterface;


class TaxonomieMultiSelectProvider implements SelectOptionsProviderInterface
{
    public function getOptions(array $context, Data $fieldDefinition): array
    {
        $entries = new DataObject\Taxonomie\Listing();
        $result = array();
        $target = $fieldDefinition->optionsProviderData;
        $zwischenSpeicher = array();
        foreach($entries as $entry) {
            $path = $entry->getPath();
            if (strpos($path, $target) > 0) {
                $push = array(
                    "key" => $entry->getBezeichnung(),
                    "value" => $entry->getId(),
                );
                array_push($result, $push);
            }
////            if (empty($entry->getParentattribute())) {
//                $path = $entry->getPath();
//                if (strpos($path, $target) > 0) {
//                    $zwischenSpeicher[$entry->getBezeichnung()]['id'] = $entry->getId();
//                    $zwischenSpeicher[$entry->getBezeichnung()]['bezeichnung'] = $entry->getBezeichnung();
//                 }
////            }
        }
//        foreach ($zwischenSpeicher as $key=>$item) {
//            foreach ($entries as $entry) {
//                $path = $entry->getParentattribute();
//                $path = implode(";", $path);
//                $subPath = str_replace("/", "", $path);
//                $subPath = substr($path, -strlen($key));
//
////                if (strpos($path, $key) > 0) {
//                if (strpos($path, $target) > 0 && $subPath === $key) {
//                    if (!isset($zwischenSpeicher[$key]['subItems'])) {
//                        $zwischenSpeicher[$key]['subItems'] = array();
//                    }
//                    $push = array(
//                        "key" => $entry->getBezeichnung(),
//                        "value" => $entry->getId(),
//                    );
//                    array_push($zwischenSpeicher[$key]['subItems'], $push);
//                }
//            }
//        }
//        foreach ($zwischenSpeicher as $key=>$item) {
//
//            if (isset($item['subItems']) && !empty($item['subItems'])) {
//                foreach ($item['subItems'] as $subitem) {
//                    $push = array(
//                        "key" => " --- " . $subitem['key'],
//                        "value" => $subitem['value'],
//                    );
//                    array_push($result, $push);
//                }
//            }
//
//        }


        return $result;
    }

    /**
     * Returns the value which is defined in the 'Default value' field
     */
    public function getDefaultValue(array $context, Data $fieldDefinition): ?string
    {

        return $fieldDefinition->getDefaultValue();
    }

    public function hasStaticOptions(array $context, Data $fieldDefinition): bool
    {
        return false;
    }

}
