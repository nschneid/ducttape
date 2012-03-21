# Notice how using parameters as literals allows us to easily handle multiple languages, test sets, genres, data sizes, etc.
# TODO: Specify which things are always cross products and which things default to baseline (name starts with "&" ?) 
# NOTE: If a step ever uses the unpack operator to reference a step, it might mean that realization must always get run
# TODO: How messy does this start looking if we integrate scheduler submission?
# GRAMMAR CHANGE: Overload $ to mean both task dependence and variable resolution to allow using parameters as variables in literal filenames
# GRAMMAR CHANGE: Use * to glob and match branches (used for deciding config settings without introducing new realizations)
# GRAMMAR CHANGE: We will use square brackets with an internal colon for branch grabbing. This also opens up the possibility of omitting branch names in both declarations and branch grabs as long as "all branches of nameless branch points must have unique branch names"

# If we wanted to specify different amounts of memory per language (i.e. even more power than in align's .vmem),
# there should be a separate "input def" block
# for inputting files along with their settings (similar to a loonybin FILESYSTEM node)

[sub preproc] < in > out {
  # Notice the unimplemented usage of parameters as variables in path literals
  task tok_src: moses
                < src=(sets: train=train.$lang.$sz tune=tune.$lang.$sz test=test.$lang.$sz)
                > tok
                :: lang=de sz=(size: small=small large=large)
                :: .vmem=2gb .cpus=1 {
    $moses/scripts/tokenizer/tokenizer.pl -l $lang < $src > $tok
  }

  task tok_tgt(moses
               < tgt=(Sets: train=train.$lang.$sz tune=tune.$lang.$sz test=test.$lang.$sz)
               > tok
               :: lang=en size=(Size: small=small large=large)
               :: .vmem=2gb .cpus=1) {
    $moses/scripts/tokenizer/tokenizer.pl -l $lang < $tgt > $tok
  }
}

sub models < f e > gra_dir {
  # TODO: Split so that it can be parallelized/resumed
  [align] mgiza
          < src=$tok@tok_src[sets:train] tgt=$tok@tok_tgt[sets:train] > symmetrized
          :: .vmem=(Size: small=2gb large=16gb) .cpus=8) {
    $mgiza > $symmetrized
  }

  [build_sa] sa_extract > out {
    $sa_extract > $out
  }

  [extract_gra] sa_extract > graDir {
                < src=$tok@tok_src[sets:train] tgt=$tok@tok_tgt[sets:train] align=$symmetrized@align
                < filteredTo=(filterSet: tune=$tok@tok_src[sets:tune] test=$tok@tok_src[sets:test])
                > gra
                :: .vmem=16gb .cpus=1 {
    $sa_extract TODO $filteredTo > $gra
  }
}

[tune] cdec
       < src=$tok/tok_src[sets:tune] refs=$tok@tok_tgt[sets:tune] gra=$gra@extract_gra[filterSet:tune]
       > hyps weights
       :: .submitter=localhost /* submits its own jobs */) {
  $cdec/pro-trainer/dist-pro.pl TODO
}

[decode] cdec
         < src=$tok@tok_src[sets:test] gra=$gra@extract_gra[filterSet:test] weights=$weights@tune
         > hyps
         :: .vmem=16gb .cpus=8) {
  $cdec/decoder/cdec TODO -w $weights > $hyps
}

[score] multeval
        < hyps=(ScoreSet: tune=$hyps@tune test=$hyps@decode)
        < refs=(ScoreSet: tune=$tok@tok_tgt[sets:tune] test=$tok@tok_tgt[sets:test])
        > out
        :: .vmem=4gb .cpus=1 {
  $multeval/multeval.sh TODO $hyps $refs > $out
}

# NOTE: We could have multiple meanings of $ in the same input:
# e.g. weights=$tune/weights/$lang
# We will resolve this based on type of the name found (if there's a collision, we throw an error)

#######################
# NON-WORKFLOW ELEMENTS
#######################

key_=value

[summary sizes] {
  using |extract_gra| cdec > GraSize {
    du -sh $pt >> $PTFileSize
  }
}

[summary status] {
  |using tune| > bleu {
    fgrep bleu $out > $bleu
  }
}

[submitter sge] :: cmds vmem walltime {
  [action wrap] > wrapper {
    #$-l vmem=$vmem
    #$-l walltime=$walltime
    $cmds
  }
  [action run] < wrapper > id {
    qsub $wrapper > $id
  }
  [action poll] > done exit_code {
    TODO # insert the lengthy script needed to properly get the exit code here
  }
  [action status] > short long {
    qstat -f $id | awk '/job_state = Q/{print "queued"} /job_state = R/{print "running"}' > $short
    qstat -f $id | awk '/job_state = Q/{print "queued"} /job_state = R/{print "running for 10 min"}' > $long
  }
}
