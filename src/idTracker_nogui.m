function datosegm=idTracker_nogui(directorio,directorio_destino,n_peces,umbral,reutiliza,roi,cambiacontraste,referencias,mascara_intensmed)

encriptar=false;

try
    if nargin==0
        error('idTracker', 'No input file was specified');
    else
        [directorio, nombrearchivo, extension] = fileparts(directorio);
        if extension(1) == '.'
            extension = extension(2:end);
        end
    end

    if nombrearchivo(end)=='1'
        raizarchivos=nombrearchivo(1:end-1);
    else
        raizarchivos=nombrearchivo;
    end

    if directorio(end)~=filesep
        directorio(end+1)=filesep;
    end

    if nargin<2 || isempty(directorio_destino)
        directorio_destino=[directorio 'segm' filesep];
    end
    if isempty(dir(directorio_destino))
        mkdir(directorio_destino)
    end
    if directorio_destino(end)~=filesep
        directorio_destino(end+1)=filesep;
    end

    datosegm=directorio2datosegm(directorio,raizarchivos,directorio_destino,extension,true);
    
    datosegm.empezarsinmas=true;
    datosegm.saltatodo=false;
    datosegm.muestrapanel=false;
    datosegm.mascara=true(datosegm.tam);
    datosegm.borde=false(datosegm.tam);
    datosegm.borde(1,:)=true;
    datosegm.borde(:,1)=true;
    datosegm.borde(datosegm.tam(1),:)=true;
    datosegm.borde(:,datosegm.tam(2))=true;
    
    datosegm.raizarchivo='segm';

    if nargin<3 || isempty(n_peces)
        n_peces=3;
    elseif ischar(n_peces)
        n_peces=str2double(n_peces);
    end
    if nargin<4 || isempty(umbral)
        umbral=.85;
    end
    if nargin<5 || isempty(reutiliza)
        reutiliza=false;
    end
    if nargin<6
        roi=[];
    end
    if nargin<7 || isempty(cambiacontraste)
        cambiacontraste=false;
    end
    if nargin<8
        referencias=[];
    end
    if nargin<9
        mascara_intensmed=[];
    end

    if length(reutiliza)==1
        datosegm.reutiliza.datosegm=reutiliza;
        datosegm.reutiliza.Background=reutiliza;
        datosegm.reutiliza.Segmentation=reutiliza;
        datosegm.reutiliza.Trozos=reutiliza;
        datosegm.reutiliza.Individualization=reutiliza;
        datosegm.reutiliza.Resegmentation=reutiliza;
        datosegm.reutiliza.References=reutiliza;
        datosegm.reutiliza.Identification=reutiliza;
        datosegm.reutiliza.Trajectories=reutiliza;
        datosegm.reutiliza.FillGaps=reutiliza;
    end

    datosegm.n_peces=n_peces;
    datosegm.umbral=umbral;
    datosegm.roi=roi;
    datosegm.cambiacontraste=cambiacontraste;

    datosegm.primerframe_intervalosbuenos=1;
    datosegm.interval=[1 size(datosegm.frame2archivo,1)];
    datosegm.nframes_refs=3000;
    datosegm.ratio_bwdist=2;
    datosegm.reduceresol=1; % Para moscas
    datosegm.n_procesadores=Inf;
    datosegm.umbral_npixels=250;
    datosegm.limpiamierda=true;
    datosegm.refsantiguas=false;
    % Cosas que todav�a falta integrar en el panel:
    datosegm.mascara_intensmed=mascara_intensmed;
    
    datosegm.version='20140805T102158';
    datosegm.version_numero='2.1';
    versioninfo.version=datosegm.version;
    versioninfo.version_numero=datosegm.version_numero;    
    save versioninfo versioninfo
    datosegm.MatlabVersion=version;
    [~, datosegm.ordenata]=system('hostname');   
    datosegm.guarda_menorescell=false;
    datosegm.max_framesportrozo=1000;
    datosegm.max_manchas.relativo=2;
    datosegm.max_manchas.absoluto=10;
    
    if encriptar || ~isfield(datosegm,'encriptar')
        datosegm.encriptar=encriptar;
    end

    datosegm=datosegm2progreso(datosegm);

    h_panel=[];
    datosegm.estilopixelsmierda=1;


    if ~isfield(datosegm,'trueno') || isempty(datosegm.trueno)
        datosegm.trueno=false;
    end
    disp('Guarning!')

    if str2double(datosegm.MatlabVersion(1))>=9
        MyPool = gcp('nocreate');
        if isempty(MyPool)
            MyPool = parpool();
        end
    else
        if matlabpool('size')==0
            matlabpool open
        end     
    end
    if ~isfield(datosegm,'muestrapanel') || datosegm.muestrapanel
        [datosegm,h_panel]=panel_identitracking(datosegm);
    end
    if ~isfield(datosegm,'ratio_bwdist')
        error('It seems that the video was tracked with an older version of idTracker, not compatible with the new version. Please, erase or rename the folder called "segm", and try to re-track the video from the beginning')
    end
    datosegm.tiempos.total(1)=now;
    datosegm.tiempos.tiempoguardando=0;
    if ~isfield(datosegm,'blancoynegro') || isempty(datosegm.blancoynegro)
        datosegm.tiempos.colorbn(1)=now;
        datosegm=datosegm2colorbn(datosegm);
        datosegm.tiempos.colorbn(2)=now;
    end
    datosegm.umbral_npixelsmax=10000*datosegm.reduceresol^2;
    tic
    variable=datosegm;
    save([datosegm.directorio 'datosegm.mat'], 'variable')
    datosegm.tiempos.tiempoguardando=datosegm.tiempos.tiempoguardando+toc;

    if ~isfield(datosegm,'saltatodo') || ~datosegm.saltatodo
        if str2double(datosegm.MatlabVersion(1))>=9
            nprocesadores_abiertos=MyPool.NumWorkers;
        else
            nprocesadores_abiertos=matlabpool('size');
        end
        if nprocesadores_abiertos~=datosegm.n_procesadores && (datosegm.n_procesadores~=Inf || nprocesadores_abiertos~=feature('numCores'))
            if str2double(datosegm.MatlabVersion(1))>=9
                if nprocesadores_abiertos~=0
                        delete(MyPool)
                end
                if datosegm.n_procesadores==Inf
                        MyPool = parpool();
                else
                        MyPool = parpool(datosegm.n_procesadores);
                end
            else
                if nprocesadores_abiertos~=0
                    matlabpool close
                end
                if datosegm.n_procesadores==Inf
                    matlabpool open % Configuraci�n por defecto del ordenador
                else
                    matlabpool('open','local',datosegm.n_procesadores)
                end
            end
        end

        if str2double(datosegm.MatlabVersion(1))>=9
            datosegm.n_procesadores_real=MyPool.NumWorkers;
        else
            datosegm.n_procesadores_real=matlabpool('size');
        end

        if isfield(h_panel,'n_procesadores') && ishandle(h_panel.n_procesadores)
            set(h_panel.n_procesadores,'String',num2str(datosegm.n_procesadores_real))
            drawnow
        end

        if isfield(datosegm,'empezarsinmas') && datosegm.empezarsinmas==1
            datosegm.reutiliza.Background=1;
            datosegm.reutiliza.Segmentation=1;
            datosegm.reutiliza.Individualization=1;
            datosegm.reutiliza.Trozos=1;
            datosegm.reutiliza.Resegmentation=1;
            datosegm.reutiliza.References=1;
            datosegm.reutiliza.Identification=1;
            datosegm.reutiliza.Trajectories=1;
            datosegm.reutiliza.FillGaps=1;
            variable=datosegm;
            save([datosegm.directorio 'datosegm.mat'],'variable')
        end

        % V�deo medio
        n_frames=size(datosegm.frame2archivo,1);
        if datosegm.limpiamierda && (~isfield(datosegm,'videomedio') || isempty(datosegm.videomedio) || ~datosegm.reutiliza.Background)
            datosegm.tiempos.videomedio(1)=now;
            if isempty(h_panel) || ~ishandle(h_panel.fig)
                fprintf('V�deo medio\n')
            end
            datosegm=datosegm2videomedio(datosegm,100,h_panel);
            if datosegm.limpiamierda
                datosegm=datosegm2datosegm_pixelsmierda(datosegm);
            end
            datosegm.tiempos.videomedio(2)=now;
            tic
            variable=datosegm;
            save([datosegm.directorio 'datosegm.mat'],'variable')
            datosegm.tiempos.tiempoguardando=datosegm.tiempos.tiempoguardando+toc;
        end

        % Segmentaci�n, solapamiento y mapas
        if isempty(h_panel) || ~ishandle(h_panel.fig)
            fprintf('Segmentaci�n, solapamiento y mapas\n')
        end
        if ~datosegm.reutiliza.Segmentation || isempty(dir([datosegm.directorio 'segm_' num2str(size(datosegm.archivo2frame,1)) '.mat']))
            datosegm.tiempos.segm(1)=now;
            [datosegm,solapamiento,npixels,segmbuena,borde,mancha2centro,max_bwdist,bwdist_centro,max_distacentro]=datosegm2segm(datosegm,h_panel);
            datosegm.tiempos.segm(2)=now;
            tic
            variable=datosegm;
            save([datosegm.directorio 'datosegm.mat'],'variable')
            variable=solapamiento;
            save([datosegm.directorio 'solapamiento.mat'],'variable')
            npixelsyotros.npixels=npixels;
            npixelsyotros.segmbuena=segmbuena;
            npixelsyotros.borde=borde;
            npixelsyotros.mancha2centro=mancha2centro;
            npixelsyotros.max_bwdist=max_bwdist;
            npixelsyotros.bwdist_centro=bwdist_centro;
            npixelsyotros.max_distacentro=max_distacentro;
            variable=npixelsyotros;
            save([datosegm.directorio 'npixelsyotros'],'variable')
            datosegm.tiempos.tiempoguardando=datosegm.tiempos.tiempoguardando+toc;
        else
            if isempty(h_panel)
                fprintf('Reutiliza segmentaci�n anterior.\n')
            end
            load([datosegm.directorio 'datosegm.mat'])
            datosegm=variable;
            load([datosegm.directorio 'solapamiento.mat'])
            solapamiento=variable;
            load([datosegm.directorio 'npixelsyotros'])
            npixelsyotros=variable;
            npixels=npixelsyotros.npixels;
            segmbuena=npixelsyotros.segmbuena;
            borde=npixelsyotros.borde;
            mancha2centro=npixelsyotros.mancha2centro;
        end
        clear npixelsyotros
        if (~isfield(datosegm,'trueno') || ~(datosegm.trueno==1))
            if (~datosegm.reutiliza.Trozos || isempty(dir([datosegm.directorio 'trozos.mat'])))
                if datosegm.n_peces>1 || (isfield(datosegm,'siemprerefs') && datosegm.siemprerefs)
                    datosegm.tiempos.trozos(1)=now;
                    [trozos,solapos]=solapamiento2trozos(solapamiento,npixels,datosegm,mancha2centro);                        
                else
                    trozos=solapamiento2trozos(solapamiento,npixels,datosegm,mancha2centro);
                    solapos=[];
                end
                [conectan,conviven,solapan]=trozos2conectatrozos(trozos,solapamiento);
                datosegm.tiempos.trozos(2)=now;
                tic
                save([datosegm.directorio 'conectanconviven.mat'],'conectan','conviven','solapan')
                variable=datosegm;
                save([datosegm.directorio 'datosegm.mat'],'variable')
                trozosolapos.trozos=trozos;
                trozosolapos.solapos=solapos;
                variable=trozosolapos;
                save([datosegm.directorio 'trozos'],'variable')
                datosegm.tiempos.tiempoguardando=datosegm.tiempos.tiempoguardando+toc;
            else
                load([datosegm.directorio 'trozos.mat']);
                trozosolapos=variable;
                trozos=trozosolapos.trozos;
                solapos=trozosolapos.solapos;
                if ~isempty(dir([datosegm.directorio 'conectanconviven.mat']))
                    load([datosegm.directorio 'conectanconviven.mat'])
                end
            end
            clear trozosolapos
        end

        if ~isfield(datosegm,'trueno') || ~(datosegm.trueno==1) % trueno ser� 2 cuando est� preparado para continuar en el cluster.
            % Si es necesario, recalcula tam_mapas (esto no deber�a hacer falta
            % pr�cticamente nunca, s�lo cuando se ha cancelado el tracking en
            % un momento muy concreto de la segmentaci�n de algunos v�deos)
            if ~isfield(datosegm,'tam_mapas')
                load([datosegm.directorio 'npixelsyotros.mat']);
                npixelsyotros=variable;
                ind_mapa=find(npixelsyotros.segmbuena & ~npixelsyotros.borde,1);
                [ind_frame,ind_mancha]=ind2sub(size(npixelsyotros.segmbuena),ind_mapa);
                load([datosegm.directorio 'segm_' num2str(datosegm.frame2archivo(ind_frame,1)) '.mat']);
                segm=variable;
                datosegm.tam_mapas=size(segm(datosegm.frame2archivo(ind_frame,2)).mapas{ind_mancha});
                variable=datosegm;
                save([datosegm.directorio 'datosegm.mat'],'variable')
            end

            % Crea las referencias para distinguir peces individuales de manchas
            % m�ltiples.
            nframes_refindiv=5;
            refs_indiv=NaN([datosegm.tam_mapas nframes_refindiv*datosegm.n_peces]);
            if datosegm.n_peces>1 || (isfield(datosegm,'siemprerefs') && datosegm.siemprerefs)
                if isempty(referencias)
                    % Asume que los frames con igual n�mero de manchas que de peces
                    % tienen todas las manchas individuales
                    if ~datosegm.reutiliza.Individualization || isempty(dir([datosegm.directorio 'refs_indiv.mat']))
                        framesbuenos=find(datosegm.n_manchas==datosegm.n_peces);
                        c_refs=0;
                        for c_frames=1:nframes_refindiv
                            randframe=ceil(rand*length(framesbuenos));
                            if randframe==0
                                disp('Warning: randframe is 0')
                                randframe=1;
                            end
                            frame=framesbuenos(randframe); % Coge uno al azar
                            archivo_act=datosegm.frame2archivo(frame,1);
                            frame_arch=datosegm.frame2archivo(frame,2);
                            load([datosegm.directorio datosegm.raizarchivo '_' num2str(archivo_act)])
                            segm=variable;
                            for c_peces=1:datosegm.n_peces
                                if ~isempty(segm(frame_arch).mapas{c_peces})
                                    c_refs=c_refs+1;
                                    refs_indiv(:,:,:,c_refs)=segm(frame_arch).mapas{c_peces};
                                end
                            end % c_peces
                        end % c_frames
                        refs_indiv=refs_indiv(:,:,:,1:c_refs);
                        ranmat_validos=datosegm.indvalidos;
                        indvalidos{1}=find(mat_validos(:,:,1));
                        mat_validos(:,:,1)=false;
                        indvalidos{2}=find(mat_validos);
                        [menores,errores_pezindiv]=comparamapas(refs_indiv,{refs_indiv},indvalidos);
                        errores_pezindiv=errores_pezindiv{1};
                        errores_pezindiv(errores_pezindiv==0)=NaN;
                        errores_pezindiv=squeeze(min(errores_pezindiv,[],1));
                        errores_pezindiv=sum(errores_pezindiv,2);
                        refsindiv.refs_indiv=refs_indiv;
                        refsindiv.errores_pezindiv=errores_pezindiv;
                        variable=refsindiv;
                        save([datosegm.directorio 'refs_indiv.mat'],'variable')
                        datosegm.umbral_errorindiv=mean(errores_pezindiv)+std(errores_pezindiv)*3; % Damos 3 sd's.
                        variable=datosegm;
                        save([datosegm.directorio 'datosegm.mat'],'variable')
                        clear segm
                    else
                        fprintf('Reutiliza referencias individuales.\n')
                        load([datosegm.directorio 'refs_indiv.mat'])
                        refsindiv=variable;
                        refs_indiv=refsindiv.refs_indiv;
                        errores_pezindiv=refsindiv.errores_pezindiv;
                    end
                    clear refsindiv
                else
                    disp('Guarning! Usa 10 sd para las manchas individuales, y cuando son refs. internas usa 3 sd')
                    nframes_refindiv=ceil(100/datosegm.n_peces);
                    n_refs=length(referencias);
                    refs_indiv=NaN([datosegm.tam_mapas nframes_refindiv*n_refs]);
                    cframes_tot=0;
                    for c_refs=1:n_refs
                        n_frames=size(referencias{c_refs},4);
                        indices=equiespaciados(nframes_refindiv,n_frames);
                        for c_frames=indices
                            cframes_tot=cframes_tot+1;
                            refs_indiv(:,:,:,cframes_tot)=referencias{c_refs}(:,:,:,c_frames);
                        end % c_frames
                    end % c_refs
                    mat_validos=datosegm.indvalidos;
                    indvalidos{1}=find(mat_validos(:,:,1));
                    mat_validos(:,:,1)=false;
                    indvalidos{2}=find(mat_validos);
                    [menores,errores_pezindiv]=comparamapas(refs_indiv,{refs_indiv},indvalidos);
                    errores_pezindiv=errores_pezindiv{1};
                    errores_pezindiv(errores_pezindiv==0)=NaN;
                    errores_pezindiv=squeeze(min(errores_pezindiv,[],1));
                    errores_pezindiv=sum(errores_pezindiv,2);
                    refsindiv.refs_indiv=refs_indiv;
                    refsindiv.errores_pezindiv=errores_pezindiv;
                    variable=refsindiv;
                    save([datosegm.directorio 'refs_indiv.mat'],'variable')
                    datosegm.umbral_errorindiv=mean(errores_pezindiv)+std(errores_pezindiv)*10; % Damos 10 sd's. Cambio de 3 a 10 el 24 de feb del 12. Quiz� 3 estaba bien para los v�deos de cerca, pero no para los de lejos.
                    variable=datosegm;
                    save([datosegm.directorio 'datosegm.mat'],'variable')
                    clear refsindiv
                end
            else
                refs_indiv=[];
            end

            % Distingue manchas individuales de manchas colectivas. Siempre asume que
            % cuando hay tantas manchas como peces, son todas individuales
            n_archivos=size(datosegm.archivo2frame,1);
            load([datosegm.directorio datosegm.raizarchivo '_' num2str(n_archivos)]);
            segm=variable;
            if datosegm.n_peces>1 || (isfield(datosegm,'siemprerefs') && datosegm.siemprerefs)
                if ~datosegm.reutiliza.Individualization || ~isfield(segm,'indiv') || isempty(dir([datosegm.directorio 'indiv.mat']))
                    datosegm.tiempos.indiv(1)=now;
                    indiv=datosegm2segm_indiv(datosegm,refs_indiv,h_panel); % Indiv se va guardando desde dentro                        
                    datosegm.tiempos.indiv(2)=now;
                    variable=datosegm;
                    save([datosegm.directorio 'datosegm.mat'],'variable')
                else
                    disp('Reutiliza identificaci�n de manchas individuales')
                    load([datosegm.directorio 'indiv.mat'])
                    indiv=variable;
                end
            end

            % Resegmentaci�n
            if datosegm.n_peces>1 && (~isfield(datosegm,'resegmentar') || datosegm.resegmentar)
                n_archivos=size(datosegm.archivo2frame,1);
                load([datosegm.directorio datosegm.raizarchivo '_' num2str(n_archivos)])
                segm=variable;
                if ~datosegm.reutiliza.Resegmentation || ~isfield(segm,'resegmentado')
                    % Resegmentaci�n (todo se guarda dentro)
                    datosegm.tiempos.resegmentacion(1)=now;
                    [datosegm,npixelsyotros,solapamiento,trozos,solapos,conectan,conviven,solapan,indiv]=datosegm2resegmentacion(datosegm,h_panel);
                    campos=fieldnames(npixelsyotros);
                    for c_campos=1:length(campos)
                        eval([campos{c_campos} '=npixelsyotros.' campos{c_campos} ';'])
                    end
                    % Se asegura de que el �ltimo segm tenga el campo
                    % resegmentado, para saber luego si este paso ha
                    % terminado
                    n_archivos=size(datosegm.archivo2frame,1);
                    load([datosegm.directorio datosegm.raizarchivo '_' num2str(n_archivos)])
                    segm=variable;
                    if ~isfield(segm,'resegmentado')
                        segm(1).resegmentado=[];
                    end
                    variable=segm;
                    save([datosegm.directorio datosegm.raizarchivo '_' num2str(n_archivos)],'variable')
                    datosegm.tiempos.resegmentacion(2)=now;
                    variable=datosegm;
                    save([datosegm.directorio 'datosegm.mat'],'variable')
                else
                    disp('Reutiliza resegmentaci�n')
                end
            end

            if isempty(referencias) && (~isfield(datosegm,'stopafterresegmentation') || ~datosegm.stopafterresegmentation)
                if datosegm.n_peces>1 || (isfield(datosegm,'siemprerefs') && datosegm.siemprerefs)
                    % Intervalos v�lidos para las referencias
                    fprintf('Intervalos buenos\n')
                    if ~datosegm.reutiliza.References || isempty(dir([datosegm.directorio 'intervalosbuenos.mat']))
                        if datosegm.refsantiguas
                            intervalosbuenos=datosegm2intervalosbuenos_20120724T110320(datosegm,datosegm.primerframe_intervalosbuenos);
                        else
                            datosegm.tiempos.intervalosbuenos(1)=now;                                
                            intervalosbuenos=datosegm2intervalosbuenos(datosegm,trozos,solapos,indiv,segmbuena,borde,datosegm.primerframe_intervalosbuenos,1);
                            datosegm.tiempos.intervalosbuenos(2)=now;
                            variable=datosegm;
                            save([datosegm.directorio 'datosegm.mat'],'variable')
                        end
                        tic
                        variable=intervalosbuenos;
                        save([datosegm.directorio 'intervalosbuenos.mat'],'variable')
                        datosegm.tiempos.tiempoguardando=datosegm.tiempos.tiempoguardando+toc;
                    else
                        fprintf('Reutiliza intervalosbuenos.\n')
                        load([datosegm.directorio 'intervalosbuenos.mat'])
                        intervalosbuenos=variable;
                    end

                    % Referencias
                    fprintf('Referencias\n')
                    if ~datosegm.reutiliza.References || isempty(dir([datosegm.directorio 'referencias.mat']))
                        if datosegm.refsantiguas
                            [referencias,framesescogidos]=datosegm2referencias_20120724T172537(datosegm,intervalosbuenos,datosegm.nframes_refs);
                            listamapas=[];
                        else
                            datosegm.tiempos.referencias(1)=now;
                            [referencias,listamapas]=datosegm2referencias(datosegm,intervalosbuenos,trozos,datosegm.nframes_refs,h_panel);
                            datosegm.tiempos.referencias(2)=now;
                            variable=datosegm;
                            save([datosegm.directorio 'datosegm.mat'],'variable')
                        end
                        tic
                        refs.referencias=referencias;
                        refs.listamapas=listamapas;
                        variable=refs;
                        save([datosegm.directorio 'referencias.mat'],'variable')
                        datosegm.tiempos.tiempoguardando=datosegm.tiempos.tiempoguardando+toc;
                    else
                        fprintf('Reutiliza referencias.\n')
                        load([datosegm.directorio 'referencias.mat'])
                        refs=variable;
                        referencias=refs.referencias;
                        listamapas=refs.listamapas;
                    end
                    clear refs
                else
                    refs.referencias=[];
                    refs.listamapas=[];
                    variable=refs;
                    save([datosegm.directorio 'referencias'],'variable');
                    clear refs
                end
            else
                refs.referencias=referencias;
                refs.listamapas=[];
                variable=refs;
                save([datosegm.directorio 'referencias'],'variable')
                clear refs
            end

            % Trozos, probabilidades y trayectorias
            if isfield(datosegm,'stopafterresegmentation') && datosegm.stopafterresegmentation
                datosegm.solohastareferencias=true;
            end 

            if ~isfield(datosegm,'solohastareferencias') || ~datosegm.solohastareferencias
                % Limpio la memoria con la esperanza de que ayude algo
                a=who;
                for c=1:length(a)
                    if ~strcmp(a{c},'datosegm') && ~strcmp(a{c},'h_panel') && ~strcmp(a{c},'a')
                        clear(a{c})
                    end
                end
                clear a
                encriptar=datosegm.encriptar;

                if datosegm.n_peces>1 || (isfield(datosegm,'siemprerefs') && datosegm.siemprerefs)
                    load([datosegm.directorio 'referencias'])
                    refs=variable;
                    referencias=refs.referencias;
                    clear refs
                end
                load([datosegm.directorio 'trozos'])
                trozosolapos=variable;
                trozos=trozosolapos.trozos;
                solapos=trozosolapos.solapos;
                clear trozosolapos

                if datosegm.progreso.Identification<1 || ~datosegm.reutiliza.Identification
                    if datosegm.n_peces>1 || (isfield(datosegm,'siemprerefs') && datosegm.siemprerefs)
                        mat_validos=datosegm.indvalidos;
                        indvalidos{1}=find(mat_validos(:,:,1));
                        mat_validos(:,:,1)=false;
                        indvalidos{2}=find(mat_validos);
                        datosegm.tiempos.identificacion(1)=now;
                        mancha2id=trozos2mancha2id(datosegm,trozos,solapos,indvalidos,referencias,[],1,h_panel); % mancha2id se guarda autom�ticamente desde dentro del programa
                        datosegm.tiempos.identificacion(2)=now;
                        variable=datosegm;
                        save([datosegm.directorio 'datosegm.mat'],'variable')
                    else
                        load([datosegm.directorio 'npixelsyotros'])
                        npixelsyotros=variable;
                        load([datosegm.directorio 'conectanconviven'])
                        identificaciones.mancha2id=trozos2mancha2id_unbicho(trozos,npixelsyotros.mancha2centro,conviven);
                        mancha2id=identificaciones.mancha2id;
                        variable=identificaciones;
                        save([datosegm.directorio 'mancha2id'],'variable')
                    end
                else
                    load([datosegm.directorio 'mancha2id.mat']);
                    man2id=variable;
                    mancha2id=man2id.mancha2id;
                    disp('Reutiliza identificaci�n')
                end

                if datosegm.n_peces>1 || (isfield(datosegm,'siemprerefs') && datosegm.siemprerefs)
                    clear referencias
                    if ~isempty(h_panel)
                        set(h_panel.waitTrajectories,'XData',[0 0 .1 .1])
                        set(h_panel.textowaitTrajectories,'String',[num2str(round(sum(.1)*100)) ' %'])
                    end
                    load([datosegm.directorio 'solapamiento']);     
                    solapamiento=variable;
                    if ~isempty(h_panel)
                        set(h_panel.waitTrajectories,'XData',[0 0 .25 .25])
                        set(h_panel.textowaitTrajectories,'String',[num2str(round(sum(.25)*100)) ' %'])
                    end
                    idtrozos=mancha2id2idtrozos(datosegm,trozos,solapos,mancha2id);
                    probtrozos=idtrozos2probtrozos(idtrozos);
                    idprobtrozos.idtrozos=idtrozos;
                    idprobtrozos.probtrozos=probtrozos;
                    variable=idprobtrozos;
                    save([datosegm.directorio 'idtrozos.mat'],'variable')
                    clear idprobtrozos
                    if ~isempty(h_panel)
                        set(h_panel.waitTrajectories,'XData',[0 0 .5 .5])
                        set(h_panel.textowaitTrajectories,'String',[num2str(round(sum(.5)*100)) ' %'])
                    end

                    load([datosegm.directorio 'conectanconviven.mat'])
                    [mancha2pez,trozo2pez,probtrozos_relac]=probtrozos2identidades(trozos,probtrozos,conviven);
                    man2pez.mancha2pez=mancha2pez;
                    man2pez.trozo2pez=trozo2pez;
                    man2pez.probtrozos_relac=probtrozos_relac;
                else
                    mancha2pez=mancha2id;
                    mancha2pez(mancha2pez==0)=NaN;
                    man2pez.mancha2pez=mancha2pez;
                    probtrozos_relac=[];
                end
                variable=man2pez;
                save([datosegm.directorio 'mancha2pez.mat'],'variable')
                clear man2pez

                if ~isempty(h_panel)
                    set(h_panel.waitTrajectories,'XData',[0 0 .75 .75])
                    set(h_panel.textowaitTrajectories,'String',[num2str(round(sum(.75)*100)) ' %'])
                    set(h_panel.waitTrajectories,'XData',[0 0 1 1])
                    set(h_panel.textowaitTrajectories,'String',[num2str(round(sum(1)*100)) ' %'])
                end

                load([datosegm.directorio 'mancha2pez.mat'])
                man2pez=variable;
                load([datosegm.directorio 'npixelsyotros.mat'])
                npixelsyotros=variable;
                [trajectories,probtrajectories]=mancha2pez2trayectorias(datosegm,man2pez.mancha2pez,trozos,[],npixelsyotros.mancha2centro);
                save([datosegm.directorio 'trajectories.mat'],'trajectories','probtrajectories')
                trajectories2txt(trajectories,probtrajectories,[datosegm.directorio 'trajectories.txt'])

                datosegm.tiempos.fillgaps(1)=now;
                if datosegm.n_peces>1
                    datosegm2smartinterp2(datosegm,h_panel);
                    load([datosegm.directorio 'mancha2pez_nogaps.mat'])          
                    man2pez=variable;
                    [trajectories,probtrajectories]=mancha2pez2trayectorias(datosegm,man2pez.mancha2pez,trozos,man2pez.probtrozos_relac,man2pez.mancha2centro);
                    probtrajectories(man2pez.tiporefit==1)=-1;
                    probtrajectories(man2pez.tiporefit>=2)=-2;
                    save([datosegm.directorio 'trajectories_nogaps.mat'],'trajectories','probtrajectories')
                    trajectories2txt(trajectories,probtrajectories,[datosegm.directorio 'trajectories_nogaps.txt'])
                end

                progreso=1;

                if ~isempty(h_panel)
                    set(h_panel.waitFillGaps,'XData',[0 0 progreso progreso])
                    set(h_panel.textowaitFillGaps,'String',[num2str(round(progreso*100)) ' %'])
                end

                datosegm.tiempos.fillgaps(2)=now;

                datosegm.tiempos.total(2)=now;
                variable=datosegm;
                save([datosegm.directorio 'datosegm.mat'],'variable')
                if str2double(datosegm.MatlabVersion(1))>=9
                    try
                        if MyPool.NumWorkers>0
                            delete(MyPool)
                        end
                    catch
                    end
                else
                    try
                        if matlabpool('size')>0
                            matlabpool close
                        end
                    catch
                    end
                end

                if ~isfield(datosegm,'muestrapanel') || datosegm.muestrapanel
                    close(h_panel.fig)
                    despedida(datosegm,trajectories,probtrajectories)
                end
            end % if not soloreferencias
        else
            datosegm.trueno=2; % Para que s� contin�e la pr�xima vez que se ejecute
            variable=datosegm;
            save([datosegm.directorio 'datosegm.mat'],'variable')
        end % if not trueno
    else
        close(h_panel.fig)
    end % if no saltatodo
catch me
    if str2double(datosegm.MatlabVersion(1))>=9
        try 
            delete(MyPool)
        catch
        end
    else
        try
            matlabpool close
        catch
        end
    end
    if nargin==0
        boton='Exit & create error log file';
        if strcmpi(me.identifier,'idTracker:WindowClosed')
            boton = questdlg('It seems you have closed idTracker. The tracking has stoped.','idTracker has closed','Exit','Exit & create error log file','Exit');
        end
        if strcmpi(boton,'Exit & create error log file')
            erroraco.me.identifier=me.identifier; % Voy campo por campo para que quede en un struct en vez de en un error object
            erroraco.me.message=me.message;
            erroraco.me.cause=me.cause;
            erroraco.me.stack=me.stack;
            try
                if exist('datosegm','var')
                    erroraco.datosegm=datosegm;
                    variable=erroraco;
                    save([datosegm.directorio 'idTrackerError' datestr(now,30)],'variable')
                    errorfile=[datosegm.directorio 'idTrackerError' datestr(now,30)];
                else
                    variable=erroraco;
                    save(['idTrackerError' datestr(now,30)],'variable')
                    errorfile=['idTrackerError' datestr(now,30)];
                end
            catch
                error(sprintf('An error has occured, and idTracker must close.\n\nError log file could not be created (maybe your disk is full?)\n\nPlease, try again and if the error persist report it to bugs.idtracker@gmail.com\n\nSorry for the inconvenience!'))
            end
            error(sprintf('An error has occured, and idTracker must close.\nThe error was\n\n%s\n\nAn error log file has been created at\n%s\n\nPlease, try again and if the error persists send the error log file to bugs.idtracker@gmail.com\n\nSorry for the inconvenience!',me.message,errorfile))
        end % if hay error log
    else
        getReport(me)
    end
end
