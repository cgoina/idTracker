default: idTracker idTracker_batch idTrackerResults

bin:
	mkdir -p bin

idTracker: bin src/idTracker.m
	${MATLAB_ROOT}/bin/mcc \
	-v \
	-m idTracker \
	-d bin \
	-I src


idTracker_batch: bin src/idTracker_batch.m
	${MATLAB_ROOT}/bin/mcc \
	-v \
	-m idTracker_batch \
	-d bin \
	-I src

idTrackerResults: bin src/idTrackerResults.m
	${MATLAB_ROOT}/bin/mcc \
	-v \
	-m idTrackerResults \
	-d bin \
	-I src
