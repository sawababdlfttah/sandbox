public with sharing class RecordManagerController {
    	
    @AuraEnabled(cacheable=true)
    public static List<ObjectInfo> getObjectsList() {
        List<ObjectInfo> objectInfos = new List<ObjectInfo>();
        
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for(String sObj : gd.keySet()) {
            Schema.DescribeSObjectResult describeResult = gd.get(sObj).getDescribe();
            
            if(describeResult.isAccessible() && 
               !describeResult.isCustomSetting() && 
               !sObj.endsWith('__Share') && 
               !sObj.endsWith('__History') && 
               !sObj.endsWith('__Feed')) {
                
                objectInfos.add(new ObjectInfo(
                    describeResult.getLabel(),
                    describeResult.getName()
                ));
            }
        }
        
        objectInfos.sort();
        return objectInfos;
    }
    
    @AuraEnabled
    public static RecordsResult getRecords(String objectApiName) {
        RecordsResult result = new RecordsResult();
        
        try {
            Schema.DescribeSObjectResult objectDescribe = 
                Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
            List<Map<String, Object>> columns = new List<Map<String, Object>>();
            
            // Construire la requête SOQL en garantissant les champs Name/Title
            String soql = 'SELECT Id';
            
            // Trouver le champ Name ou équivalent pour l'objet
            String nameField = findNameField(objectApiName, fieldMap);
            if (nameField != null && nameField != 'Id') {
                soql += ', ' + nameField;
                
                // Ajouter la colonne Name en premier
                Map<String, Object> nameColumn = new Map<String, Object>{
                    'label' => 'Name',
                    'fieldName' => nameField,
                    'type' => 'text'
                };
                columns.add(nameColumn);
            }
            
            // Ajouter d'autres champs importants
            List<String> importantFields = new List<String>{
                'Name', 'Title', 'Email', 'Phone', 'Status'
            };
            
            for (String fieldName : importantFields) {
                if (fieldMap.containsKey(fieldName) && fieldName != nameField && fieldName != 'Id') {
                    Schema.DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();
                    if (field.isAccessible()) {
                        soql += ', ' + fieldName;
                        
                        Map<String, Object> column = new Map<String, Object>{
                            'label' => field.getLabel(),
                            'fieldName' => fieldName,
                            'type' => getFieldType(field.getType().name())
                        };
                        columns.add(column);
                    }
                }
            }
            
            // Ajouter d'autres champs jusqu'à 8 colonnes
            for (String fieldName : fieldMap.keySet()) {
                if (columns.size() >= 8) break;
                
                if (!importantFields.contains(fieldName) && fieldName != nameField && fieldName != 'Id') {
                    Schema.DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();
                    
                    if (field.isAccessible() && !fieldName.endsWith('__r')) {
                        soql += ', ' + fieldName;
                        
                        Map<String, Object> column = new Map<String, Object>{
                            'label' => field.getLabel(),
                            'fieldName' => fieldName,
                            'type' => getFieldType(field.getType().name())
                        };
                        columns.add(column);
                    }
                }
            }
            
            soql += ' FROM ' + objectApiName + ' LIMIT 100';
            result.columns = columns;
            
            // Exécuter la requête
            result.records = Database.query(soql);
            return result;
            
        } catch(Exception e) {
            throw new AuraHandledException('Error retrieving records: ' + e.getMessage());
        }
    }
    
    // Méthode pour trouver le champ Name ou équivalent pour un objet
    private static String findNameField(String objectName, Map<String, Schema.SObjectField> fieldMap) {
        // Priorité des champs de nom potentiels
        List<String> possibleNameFields = new List<String>{
            'Name', 'Title', 'Subject', 'CaseNumber', 'OrderNumber', 'ContractNumber',
            'FirstName', 'LastName', 'FullName', 'Label'
        };
        
        // Vérifier si l'objet a un champ Name
        for (String nameField : possibleNameFields) {
            if (fieldMap.containsKey(nameField)) {
                Schema.DescribeFieldResult field = fieldMap.get(nameField).getDescribe();
                if (field.isAccessible()) {
                    return nameField;
                }
            }
        }
        
        // Si aucun champ de nom standard, chercher un champ personnalisé avec "Name" dans le label
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();
            if (field.isAccessible() && 
                (field.getLabel().contains('Name') || field.getLabel().contains('Nom')) && 
                field.getType() == Schema.DisplayType.STRING) {
                return fieldName;
            }
        }
        
        // Si toujours rien, simplement retourner le premier champ texte accessible
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult field = fieldMap.get(fieldName).getDescribe();
            if (field.isAccessible() && field.getType() == Schema.DisplayType.STRING) {
                return fieldName;
            }
        }
        
        return null;
    }
    
    @AuraEnabled
    public static void deleteRecords(String objectName, List<String> recordIds) {
        try {
            Schema.DescribeSObjectResult objectDescribe = 
                Schema.getGlobalDescribe().get(objectName).getDescribe();
                
            if(!objectDescribe.isDeletable()) {
                throw new AuraHandledException('You do not have permission to delete records from this object');
            }
            
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
            
            List<SObject> recordsToDelete = new List<SObject>();
            for(String recordId : recordIds) {
                SObject record = sObjectType.newSObject(recordId);
                recordsToDelete.add(record);
            }
            
            Database.DeleteResult[] results = Database.delete(recordsToDelete, true);
            
            List<String> errors = new List<String>();
            for(Database.DeleteResult result : results) {
                if(!result.isSuccess()) {
                    for(Database.Error err : result.getErrors()) {
                        errors.add(err.getMessage());
                    }
                }
            }
            
            if(!errors.isEmpty()) {
                throw new AuraHandledException(String.join(errors, ', '));
            }
            
        } catch(Exception e) {
            throw new AuraHandledException('Error deleting records: ' + e.getMessage());
        }
    }
    
    private static String getFieldType(String salesforceType) {
        Map<String, String> typeMap = new Map<String, String>{
            'BOOLEAN' => 'boolean',
            'CURRENCY' => 'currency',
            'DATE' => 'date',
            'DATETIME' => 'date-local',
            'EMAIL' => 'email',
            'NUMBER' => 'number',
            'PERCENT' => 'percent',
            'PHONE' => 'phone',
            'URL' => 'url'
        };
        
        return typeMap.containsKey(salesforceType) ? typeMap.get(salesforceType) : 'text';
    }
    
    public class ObjectInfo implements Comparable {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        
        public ObjectInfo(String label, String apiName) {
            this.label = label;
            this.apiName = apiName;
        }
        
        public Integer compareTo(Object compareTo) {
            ObjectInfo compareToObj = (ObjectInfo)compareTo;
            return this.label.compareTo(compareToObj.label);
        }
    }
    
    public class RecordsResult {
        @AuraEnabled public List<SObject> records;
        @AuraEnabled public List<Map<String, Object>> columns;
        
        public RecordsResult() {	
            this.records = new List<SObject>();
            this.columns = new List<Map<String, Object>>();
        }
    }
}