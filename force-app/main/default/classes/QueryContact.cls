public class QueryContact {
  public static Id getContactID(String lastName, String title) {
    try {
      Contact myContact = Database.query(
        'SELECT ID FROM Contact WHERE lastName = :lastName AND title = :title LIMIT 1'
      );
      return myContact.Id;
    } catch (Exception ex) {
      return null;
    }
  }
  
  public static Id getContactIDWithBinds(Map<String, Object> bindVars) {
    try {
      String queryString = 'SELECT ID FROM Contact WHERE ';
      List<String> conditions = new List<String>();
      
      for (String field : bindVars.keySet()) {
        conditions.add(field + ' = :' + field);
      }
      
      queryString += String.join(conditions, ' AND ') + ' LIMIT 1';
      
      Contact myContact = Database.queryWithBinds(queryString, bindVars, AccessLevel.USER_MODE);
      return myContact.Id;
    } catch (Exception ex) {
        return null;
    }
  }
}