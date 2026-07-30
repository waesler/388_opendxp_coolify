<?php

namespace App\Controller;

use \OpenDxp\Model\DataObject;
use OpenDxp\Model\DataObject\Kollektion;
use OpenDxp\Model\DataObject\Kollektion\Listing;
use OpenDxp\Model\DataObject\ClassDefinition\Data;
use OpenDxp\Model\DataObject\ClassDefinition\DynamicOptionsProvider\SelectOptionsProviderInterface;


class KollektionProvider implements SelectOptionsProviderInterface
{
    public function getOptions(array $context, Data $fieldDefinition): array
    {
        $entries = new DataObject\Kollektion\Listing();
        $result = array();
        $zwischenSpeicher = array();
        $oldPath = '';
        foreach($entries as $key=>$entry) {
           $path = $entry->getPath();
           $path = explode('/', $path);
           $path = $path[count($path) - 2];
            if ($path != $oldPath) {
                $push = array(
                    "key" => $path,
                    "value" => $key,
                );
                array_push($result, $push);
                $push = array(
                    "key" => "----" . $entry->getKollektionsname(),
                    "value" => $entry->getId(),
                );
                array_push($result, $push);
                $oldPath = $path;
            } else {
                $push = array(
                    "key" => "----" . $entry->getKollektionsname(),
                    "value" => $entry->getId(),
                );
                array_push($result, $push);
            }
            }
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
