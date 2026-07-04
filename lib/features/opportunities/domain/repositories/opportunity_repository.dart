import '../models/opportunity.dart';
import '../models/opportunity_application.dart';

abstract class OpportunityRepository {
  Stream<List<Opportunity>> streamAllOpportunities();
  Stream<List<Opportunity>> streamNgoOpportunities(String ngoId);
  Future<Opportunity> getOpportunityById(String id);
  Future<String> createOpportunity(Opportunity opportunity);
  Future<void> updateOpportunity(Opportunity opportunity);
  Future<void> deleteOpportunity(String id);
  Future<void> applyForOpportunity(OpportunityApplication application);
  Future<bool> hasAppliedForOpportunity(String opportunityId, String volunteerId);
  Stream<List<Opportunity>> streamAppliedOpportunities(String volunteerId);
  Stream<List<OpportunityApplication>> streamOpportunityApplications(String opportunityId);
  Future<void> updateApplicationStatus(String applicationId, String status);
}
