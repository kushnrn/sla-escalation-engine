public virtual class SlaTriggerHandlerBase {
    public virtual void beforeInsert(List<SObject> newRecords) {}
    public virtual void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {}
    public virtual void beforeDelete(Map<Id, SObject> oldMap) {}
    public virtual void afterInsert(List<SObject> newRecords, Map<Id, SObject> newMap) {}
    public virtual void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {}
    public virtual void afterDelete(Map<Id, SObject> oldMap) {}
    public virtual void afterUndelete(List<SObject> newRecords, Map<Id, SObject> newMap) {}
}
