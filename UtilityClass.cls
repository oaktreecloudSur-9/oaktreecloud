////////////////////////////////////////////////////////////////////////
//This is Utility class which is containing Genric Callout's,Genric Data 
//Processing, and Query sObjects and Custom setting's dynamically. 
//////////////////////////////////////////////////////////////////////// 

public class UtilityClass {
   
    public SObject getCustomSettingList(String customObjectName){
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(customObjectName).getDescribe().fields.getMap(); 
        String soqlQuery = 'SELECT ';
        for(Schema.SObjectField sfield : fieldMap.values()) {
            soqlQuery+=sfield+', ';
        }
        soqlQuery = soqlQuery.substringBeforeLast(',');
        soqlQuery= soqlQuery+' FROM '+customObjectName+' limit 1' ;
        return Database.query(soqlQuery);
    }
    
    ////////////////////////////
    // The main callout method 
    ////////////////////////////
    @future(Callout = true)
    public static void calloutMethod(String endPoint, String Methods, String requestBody, Map<String, String> headerMap,Id clientId,String objName) {
        String responseVal ;
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();
        req.setEndpoint(endpoint);
        req.setMethod(methods);
        if(requestBody != null && requestBody != '')
            req.setBody(requestBody);
        for(string header : headerMap.keySet()) {
            req.setHeader(header, headerMap.get(header));
        }
        Http http = new Http();
        try{
            resp = http.send(req);
            /////////////////////////////////////////////////////////////////////
            //To invoke data parsing method, which is parsed data based on Object
            //////////////////////////////////////////////////////////////////////
            ProcessSobjectData(resp.getBody(),'IntegrationFieldMapping__c','Client__c',clientId);
        }
        catch (exception e) {
            resp.setBody(e.getMessage());
            resp.setStatusCode(401);
        }
    }
    
    ////////////////////////////////////////////////////////////////////////
    // Query Custom settings Data for mapping Json response to the Objects
    ////////////////////////////////////////////////////////////////////////
    
    public static List<SObject> getSobjectDetail(String customObjectName, String target){
        Schema.SObjectType convertType = Schema.getGlobalDescribe().get(customObjectName);
        Map<String,Schema.SObjectField> mfields = convertType.getDescribe().fields.getMap();
        String soqlQuery = 'SELECT ';
        for(Schema.SObjectField field:mfields.values()){
            soqlQuery+=String.valueOf(field)+', ';
        }
        soqlQuery = soqlQuery.substringBeforeLast(',');
        soqlQuery= soqlQuery+' FROM '+customObjectName+' where Target_Object__c =\''+target+'\'' ;
        return Database.query(soqlQuery);
    } 
    
    ///////////////////////////////////////////////////////////////
    // Processing response data into Salesforce records dynamically
    ///////////////////////////////////////////////////////////////
    public static void ProcessSobjectData(String response, String Settingname, String TargetObject, id idstring) {
        List<SObject> customMapping = getSobjectDetail(Settingname,TargetObject);
        List<SObject> SobjectIntanceList = new List<SObject> ();
        Sobject ObjectType = schema.getGlobalDescribe().get(TargetObject).newSobject(idstring);
        Map<String, Object> responeMap = (Map<String, Object>)JSON.deserializeUntyped(response);
        for(SObject sobj : customMapping) {
            if(String.valueOf(responeMap.get((String)sobj.get('Source_Field__c'))) != null && String.valueOf(responeMap.get((String)sobj.get('Source_Field__c'))) != '') 
            ObjectType.put((String)sobj.get('Target_Field__c'), responeMap.get((String)sobj.get('Source_Field__c')));
        }
        SobjectIntanceList.add(ObjectType);
        ClientTriggerHandler.checkRecursive= false;
        try{
           Update SobjectIntanceList; 
        }
        catch (Exception e){}
    }
    ////////////////////////////////
    // get the custom Object record
    ////////////////////////////////
    public static SObject processData(Id clientIds,String objName){
        list<Schema.SObjectField > fieldName = new list<Schema.SObjectField >();
        fieldName.clear();
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(objName).getDescribe().fields.getMap(); 
        String soqlQuery = 'SELECT '; 
        for(Schema.SObjectField sfield : fieldMap.values()){
            soqlQuery+=sfield+', ';
        }
        soqlQuery = soqlQuery.substringBeforeLast(',');
        soqlQuery = soqlQuery+' FROM '+objName+' where Id =: clientIds  limit 1' ;
        return Database.query(soqlQuery);
    }
    //////////////////////
    //Serialize JSON Body
    //////////////////////
    public static String serializeData(Id clientId,String objName){
        SObject clientData = processData(clientId,objName);
        object2Json objJson = new object2Json();
        objJson.programName =      (String)clientData.get(Schema.Client__c.Program_Name__c);
        objJson.prospectId = (String)clientData.get(Schema.Client__c.Prospect_UUID__c);
        objJson.creditScore = (Double)clientData.get(Schema.Client__c.Credit_Score__c);
        objJson.prospectCreatedAt = (DateTime)clientData.get(Schema.Client__c.Prospect_Created_Dt__c);
        objJson.programCreatedAt =(DateTime)clientData.get(Schema.Client__c.Program_Created_Dt__c);
        objJson.originalDebtEnrolled = (Double)clientData.get(Schema.Client__c.Original_Debt_Enrolled__c);
        objJson.gender = (String)clientData.get(Schema.Client__c.Gender__c);
        objJson.dateOfBirth = (Date)clientData.get(Schema.Client__c.Date_Of_Birth__c);
        objJson.monthlyExpenses =(Double)clientData.get(Schema.Client__c.Monthly_Expenses__c);
        objJson.totalMonthlyIncome = (Double)clientData.get(Schema.Client__c.Total_Monthly_Income__c);
        objJson.paymentFrequency = (String)clientData.get(Schema.Client__c.Payment_Frequency__c);
        objJson.homeStatus = (String)clientData.get(Schema.Client__c.Home_Status__c);
        String Formatedjson = JSON.serialize(objJson);
        return Formatedjson;
    }
    /////////////////////////////
    //Wrapper class for JSON Body
    /////////////////////////////
    public class object2Json {
        public String programName;
        public String prospectId;
        public Double creditScore;
        public DateTime prospectCreatedAt;
        public DateTime programCreatedAt;
        public Double originalDebtEnrolled;
        public String gender;
        public Date dateOfBirth ;
        public Double monthlyExpenses ;
        public Double totalMonthlyIncome;
        public String paymentFrequency;
        public String homeStatus;
    }
}