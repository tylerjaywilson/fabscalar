#include "common.h"
//#include "uint.XPStack.h"
#include "ss.h"

#include <map>
using namespace std;


class branch_profile_t {
 private:
 public:
  unsigned int N;
  unsigned int m;
  branch_profile_t() {
    N = 0;
    m = 0;
  }
};


class gshare_predictor {

 private:
  //	uintXPStack RAS;

  unsigned int *JHT;
  unsigned int jht_size;

  unsigned int *PHT;
  unsigned int pht_size;

  unsigned int BHR;

  bool bimodal;

  bool profile_all_branches;
  map <unsigned int, branch_profile_t> branch_profiles;
  bool print_gsh_stats;

  // STATS
  unsigned int num_jump_directs;
  unsigned int num_call_directs;
  unsigned int num_jump_indirects;
  unsigned int num_misp_jump_indirects;
  unsigned int num_returns;
  unsigned int num_misp_returns;
  unsigned int num_call_indirects;
  unsigned int num_misp_call_indirects;
  unsigned int num_cond_branches;
  unsigned int num_misp_branches;

  double rate(unsigned int a, unsigned int b) {
    return(b ? 100.0*(double)a/(double)b : 0);
  }

  ////////////////////////
  // PRIVATE FUNCTIONS
  ////////////////////////

  bool gshare(unsigned int pc, unsigned int next_pc, bool& conf) {
    unsigned int index;
    bool prediction;
    bool outcome;
 
    index = MOD((BHR ^ (pc >> 3)), pht_size);
    prediction = (PHT[index] >= 2);
    outcome = (next_pc != (pc + SS_INST_SIZE));

    conf = ((PHT[index] == 0) || (PHT[index] == 3));

    // predictor update
    if (outcome) {
      if (PHT[index] < 3)
	PHT[index] += 1;
    }
    else {
      if (PHT[index] > 0)
	PHT[index] -= 1;
    }
    BHR = (bimodal ? 0 : ((BHR << 1) + outcome));
 
    return(prediction == outcome);
  }

  /////////////////////////////////////////////////////////////////
  // Function for predicting target of UNCONDITIONAL INDIRECTS.
  // 1. JR, where r != 31		(indirect jump)
  // 2. JALR			(indirect call)
  /////////////////////////////////////////////////////////////////
  bool uncond_indirects_corr(unsigned int pc, unsigned int target) {
    unsigned int index;
    bool correct_target;

    index = MOD((BHR ^ pc), jht_size);
    correct_target = (JHT[index] == target);
    JHT[index] = target;

    return(correct_target);
  }

  /////////////////////////////////////////////////////////////////
  // Function for predicting RETURN targets.
  // 1. JR, where R == 31		(return)
  /////////////////////////////////////////////////////////////////
  bool pop_ras(unsigned int target) {
    bool correct_target;

    //if (RAS.top() == target) {
    //   RAS.pop();
    correct_target = true;
    //}
    //else {
    //   correct_target = false;
    //}

    return(correct_target);
  }

  /////////////////////////////////////////////////////////////////
  // Function for adding CALL targets to the return address stack.
  // 1. JAL	(direct call)
  // 2. JALR	(indirect call)
  /////////////////////////////////////////////////////////////////
  void push_ras(unsigned int return_address) {
    //RAS.push(return_address);
  }

  /////////////////////////////////////////////////////////////////
  // Update stats for a specific branch.
  /////////////////////////////////////////////////////////////////
  void profile(unsigned int pc, bool misp) {
    branch_profiles[pc].N++;
    if (misp)
      branch_profiles[pc].m++;
  }

  /////////////////////////////////////////////////////////////////
  // Print out stats for all branches.
  /////////////////////////////////////////////////////////////////
  void print_branch_profiles(FILE *fp) {
    map <unsigned int, branch_profile_t>::iterator i;
    for (i = branch_profiles.begin(); i != branch_profiles.end(); i++) {
      /* 	     fprintf(fp, "%x\t%d\t%d\t%.2f\n", */
      /* 	             i->first, i->second.N, i->second.m, */
      /* 		     rate(i->second.m, i->second.N)); */
      INFO("%d\t%d\t%.2f\t%x",
	   i->second.m, i->second.N, rate(i->second.m, i->second.N), i->first);

    }
  }

 public:
  gshare_predictor(unsigned int pht_size,
		   unsigned int jht_size,
		   bool bimodal,
		   bool profile_all_branches,
		   bool print_gsh_stats)/*:RAS(32)*/ {
    unsigned int i;

    this->pht_size = pht_size;
    PHT = new unsigned int[pht_size];
    for (i = 0; i < pht_size; i++)
      PHT[i] = 2;

    this->jht_size = jht_size;
    JHT = new unsigned int[jht_size];
    for (i = 0; i < jht_size; i++)
      JHT[i] = 0;

    BHR = 0;

    this->bimodal = bimodal;
    this->profile_all_branches = profile_all_branches;
    this->print_gsh_stats = print_gsh_stats;

    // STATS
    num_jump_directs = 0;
    num_call_directs = 0;
    num_jump_indirects = 0;
    num_misp_jump_indirects = 0;
    num_returns = 0;
    num_misp_returns = 0;
    num_call_indirects = 0;
    num_misp_call_indirects = 0;
    num_cond_branches = 0;
    num_misp_branches = 0;
  }

  ~gshare_predictor() {
  }

  bool predict(SS_INST_TYPE inst,
	       unsigned int pc,
	       unsigned int next_pc,
	       bool& conf) {

    bool is_mispredict = false;

    switch(SS_OPCODE(inst)) {
    case JUMP:                                     // JUMP DIRECT
      num_jump_directs += 1;
      conf = true;
      break;

    case JAL :                                     // CALL DIRECT
      num_call_directs += 1;
      push_ras(pc + SS_INST_SIZE);     // push the ret addr onto RAS
      conf = true;
      break;

    case JR  :
      if ((RS) != 31) {                          // JUMP INDIRECT
	num_jump_indirects += 1;
	// verify prediction from JHT
	if ( !uncond_indirects_corr(pc, next_pc) ) {
	  num_misp_jump_indirects += 1;
	  is_mispredict = true;
	}
      }
      else {                                      // RETURN
	num_returns += 1;
	// verify prediction from RAS
	if ( !pop_ras(next_pc) ) {
	  num_misp_returns += 1;
	  is_mispredict = true;
	}
      }
      conf = false;
      if (profile_all_branches)
	profile(pc, is_mispredict);
      break;

    case JALR:                                     // CALL INDIRECT
      num_call_indirects += 1;
      push_ras(pc + SS_INST_SIZE);   // push the ret addr onto RAS
      // verify prediction from JHT
      if ( !uncond_indirects_corr(pc, next_pc) ) {
	num_misp_call_indirects += 1;
	is_mispredict = true;
      }
      conf = false;
      if (profile_all_branches)
	profile(pc, is_mispredict);
      break;
 
    case BEQ : case BNE : case BLEZ: case BGTZ:
    case BLTZ: case BGEZ: case BC1F: case BC1T:
      num_cond_branches += 1;
      // verify prediction
      if ( !gshare(pc, next_pc, conf) ) {
	num_misp_branches += 1;
	is_mispredict = true;
      }
      if (profile_all_branches)
	profile(pc, is_mispredict);
      break;

    default:
      break;
    }

    return(is_mispredict);
  }

  // Just get taken/not taken
  bool get_pred(unsigned int pc) {

  }



  void stats(FILE *fp) {
    unsigned int total = (num_jump_indirects + num_returns +
			  num_call_indirects + num_cond_branches);
    unsigned int misp  = (num_misp_jump_indirects + num_misp_returns +
			  num_misp_call_indirects + num_misp_branches);

    if (print_gsh_stats) {
      fprintf(fp, "------- gshare_predictor stats -------\n");
      fprintf(fp, "jump dir = %d\n", num_jump_directs);
      fprintf(fp, "call dir = %d\n", num_call_directs);
      fprintf(fp, "jump ind = %d\t%d\t%.2f%%\n",
	      num_jump_indirects, num_misp_jump_indirects,
	      rate(num_misp_jump_indirects, num_jump_indirects));
      fprintf(fp, "returns  = %d\t%d\t%.2f%%\n",
	      num_returns, num_misp_returns,
	      rate(num_misp_returns, num_returns));
      fprintf(fp, "call ind = %d\t%d\t%.2f%%\n",
	      num_call_indirects, num_misp_call_indirects,
	      rate(num_misp_call_indirects, num_call_indirects));
      fprintf(fp, "cond br  = %d\t%d\t%.2f%%\n",
	      num_cond_branches, num_misp_branches,
	      rate(num_misp_branches, num_cond_branches));
      fprintf(fp, "overall  = %d\t%d\t%.2f%%\n", total, misp,
	      rate(misp, total));
      fprintf(fp, "------- gshare_predictor stats -------\n");
    }
    fprintf(fp, "------- branch profile stats ---------\n");
    print_branch_profiles(fp);
    fprintf(fp, "------- branch profile stats ---------\n");
  }
};
