public class frSchemaUtil {

    private static Map<String, Schema.DescribeSObjectResult> describesByName;
    private static Map<String, Schema.sObjectType> typesByName;

    static {
        typesByName = new Map<String, Schema.sObjectType>();
        describesByName = new Map<String, Schema.DescribeSObjectResult>();

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for (String name : gd.keySet()) {
            typesByName.put(name.toLowerCase(), gd.get(name));
            describesByName.put(name.toLowerCase(), gd.get(name).getDescribe());
        }
    }

    public static Map<String, Schema.SObjectField> getFields(String objectName) {
        Schema.DescribeSObjectResult describe = describesByName.get(objectName.toLowerCase());
        return describe.fields.getMap();
    }

}