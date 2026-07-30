<?php

namespace App\Controller;

use \OpenDxp\Model\DataObject;
use OpenDxp\Model\DataObject\Hersteller;
use OpenDxp\Model\DataObject\Hersteller\Listing;
use OpenDxp\Model\DataObject\ClassDefinition\Data;
use OpenDxp\Model\DataObject\ClassDefinition\DynamicOptionsProvider\SelectOptionsProviderInterface;


class HerstellerProvider implements SelectOptionsProviderInterface
{
    public function getOptions(array $context, Data $fieldDefinition): array
    {
        $entries = new DataObject\Hersteller\Listing();
        $result = array();
//        $target = $fieldDefinition->optionsProviderData;
        $zwischenSpeicher = array();
        foreach ($entries as $entry) {
            $path = $entry->getPath();
//            if (strpos($path, $target) > 0) {
            $push = array(
                "key" => $entry->getHerstellerName(),
                "value" => $entry->getId(),
            );
            array_push($result, $push);
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
