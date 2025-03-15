public class ContactExtension {
    private final Contact contact;
    
    public ContactExtension(ApexPages.StandardController stdController) {
        this.contact = (Contact)stdController.getRecord();
    }
}