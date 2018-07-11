% 29-Apr-2014 10:35:20 Elimino encriptaci�n
% 21-Dec-2013 19:36:20 Hago que no guarde nada en segm, para ahorrarme
% salvarlo cada segm. ATENCI�N: AHORA menores NO SE GUARDA EN NING�N SITIO,
% NI TAMPOCO LAS MATRICES id
% 20-Dec-2013 15:19:19 Hago que por defecto no guarde menores_cell. Adem�s
% hago que no tenga que cargar segm para saber qu� frames est�n ya
% identificados
% 18-Dec-2013 14:47:24 Meto el n�mero m�ximo de frames por trozo
% 05-Sep-2013 21:29:32 Hago que pueda funcionar con v�deos anteriores a la
% encriptaci�n
% 01-Jun-2013 11:35:57 A�ado encriptaci�n
% 08-May-2013 19:01:20 Hago que guarde en un archivo fuera de segm menores e id
% 23-Apr-2013 12:50:25 Voy a volver a meter el sistema de ahorro de tiempo no identificando todos los frames en trozos largos. Pero como puede ser un infierno, 
% lo hago en trozos2mancha2id_ahorratiempo
% 19-Sep-2012 11:40:35 Hago que no realice comparaciones en v�deos de un
% solo pez.
% 08-May-2012 20:48:04 Corrijo para que no falle cuando s�lo haya un pez.
% Es un parche muy cutre, deber�a hacerlo mejor para que no haga c�lculos a
% lo bobo.
% 07-Mar-2012 17:57:14 Arreglo bugs que hab�a arreglado en el ordenador de
% Robert.
% APE 24 feb 12 Viene de trozos2id_trozos

% (C) 2014 Alfonso P�rez Escudero, Gonzalo G. de Polavieja, Consejo Superior de Investigaciones Cient�ficas

% ATENCI�N: AHORA NI menores NI LAS MATRICES id SE GUARDAN EN NING�N SITIO.
% EN SU D�A VAL�AN
% PARA ESTIMAR LA PROBABILIDAD DE LAS ASIGNACIONES. AHORA NO LOS USO, PERO
% PODR�AN SER �TILES EN ALG�N MOMENTO.

function mancha2id=trozos2mancha2id(datosegm,trozos,solapos,indvalidos,referencias,difminima,quitaborde,h_panel)

if nargin<6 || isempty(difminima)
    difminima=20; % Es el m�nimo n�mero de frames independientes que tiene que haber entre el ganador y el segundo para considerar que la identificaci�n es segura.
end

if nargin<7 || isempty(quitaborde)
    quitaborde=false;
end
if nargin<8
    h_panel=[];
end

if ~isempty(h_panel)
    set(h_panel.waitIdentification,'XData',[0 0 .01 .01])
    set(h_panel.textowaitIdentification,'String',[num2str(round(.01*100)) ' %'])
end

% Carga resultados de pasadas anteriores
if ~isempty(dir([datosegm.directorio 'mancha2id.mat']))
    load([datosegm.directorio 'mancha2id.mat'])
    identificaciones=variable;
    mancha2id=identificaciones.mancha2id;
    if isfield(identificaciones,'identificados')
        identificados=identificaciones.identificados;
    else
        identificados=mancha2id>0;
    end
    clear identificaciones
else
    mancha2id=zeros(size(trozos));
    identificados=false(size(trozos));
end

n_trozos=max(trozos(:));
% Selecciona los frames de cada trozo que identificar�
if ~isfield(datosegm,'max_framesportrozo') || isempty(datosegm.max_framesportrozo)
    datosegm.max_framesportrozo=Inf;
end
load([datosegm.directorio 'npixelsyotros.mat']);
npixelsyotros=variable;
load([datosegm.directorio 'indiv.mat'])
indiv=variable;
identificables=npixelsyotros.segmbuena & indiv & (~quitaborde | ~npixelsyotros.borde);
for c_trozos=1:n_trozos
    ind=find(trozos==c_trozos);
    if length(ind)>=datosegm.max_framesportrozo
        [frame,mancha]=ind2sub(size(trozos),ind);
        [frame,orden]=sort(frame);
        ind=ind(orden);
        n_puestos=0;
        solapos_ultimo=-Inf;
        solapos_max=max(solapos(ind));
        for c_frames=1:length(frame)
            margen_solapos=(solapos_max-solapos(ind(c_frames)))/(datosegm.max_framesportrozo-n_puestos); % Recalculo el margen cada vez
            if solapos(ind(c_frames))-solapos_ultimo<margen_solapos
                identificables(ind(c_frames))=false;
            elseif identificables(ind(c_frames))
                n_puestos=n_puestos+1;
                solapos_ultimo=solapos(ind(c_frames));
            end
        end % c_frames
    end % if hay que identificarlos todos
end % c_trozos

maxvistos=8;

nframes_min=difminima;


tam_trozos=size(trozos);
idtrozos=NaN(n_trozos,datosegm.n_peces);
n_archivos=size(datosegm.archivo2frame,1);
segmc=cell(1,n_archivos);
trozosquedan=1:n_trozos;
quedan=true(1,n_trozos);
mancha2pez=NaN(size(trozos));
archivoescoba=1;
archivo_act=0;
archivosabiertos=false(1,n_archivos);
c_trozos=0;
trozostotales=length(trozosquedan);
trozosquedan_ant=trozostotales;
n_frames=size(datosegm.frame2archivo,1);
menores_cell=cell(size(trozos,1),1);
id_cell=cell(size(trozos,1),1);
% Si s�lo hay un pez, evito que haga las comparaciones
if datosegm.n_peces==1
    vueltas=2;
else
    vueltas=[1 2];
end
for c_archivos=1:n_archivos
    fprintf('%g,',c_archivos)
    archivoabierto=false;
    nframes_act=sum(datosegm.archivo2frame(c_archivos,:)>0);
    mapas_act=NaN([datosegm.tam_mapas 2 nframes_act*datosegm.n_peces]); 
    faltanporidentificar=identificables & ~identificados;
    for c_vueltas=vueltas % En la primera vuelta acumula los mapas, y en la segunda mete los resultados de vuelta en segm
        c_mapas=0;
        for c_frames=1:nframes_act
            for c_manchas=find(faltanporidentificar(datosegm.archivo2frame(c_archivos,c_frames),:));
                %                 if identificables(datosegm.archivo2frame(c_archivos,c_frames),c_manchas) && ~identificados(datosegm.archivo2frame(c_archivos,c_frames),c_manchas)
                if ~archivoabierto % Lo abro aqu� dentro para que s�lo se abra si hace falta.
                    if isfield(datosegm,'encriptar')
                        load([datosegm.directorio datosegm.raizarchivo '_' num2str(c_archivos)])
                        segm=variable;
                    else
                        load([datosegm.directorio datosegm.raizarchivo '_' num2str(c_archivos)]);
                    end
                    if ~isfield(segm,'identificado') % Mantengo esto para que funcione el c�digo m�s adelante, pero no se guardar� (porque no guardo segm)
                        segm(1).identificado=[];
                    end
                    archivoabierto=true;
                end
                c_mapas=c_mapas+1;
                if c_vueltas==1 % La primera vuelta acumula mapas
                    mapas_act(:,:,:,c_mapas)=segm(c_frames).mapas{c_manchas};
                else % La segunda vuelta mete los resultados en segm y mancha2id
%                     if ~isfield(segm,'menores') || isempty(segm(c_frames).menores)
%                         segm(c_frames).menores=cell(1,length(segm(c_frames).mapas));
%                     end
                    if ~isfield(segm,'id') || isempty(segm(c_frames).id) % Mantengo esto para que funcione el c�digo m�s adelante, pero no se guardar� (porque no guardo segm)
                        segm(c_frames).id=zeros(length(segm(c_frames).mapas),datosegm.n_peces);
                    end
                    if datosegm.n_peces>1
                        menores_act=squeeze(menores(c_mapas,:,:)); % Cuando hay un solo pez, aqu� las dimensiones no quedan como deben.
%                         segm(c_frames).menores{c_manchas}=menores_act;
                        [m,ind]=min(menores_act,[],2);
                    else
                        ind=ones(1,2);
                    end
                    segm(c_frames).id(c_manchas,:)=zeros(1,datosegm.n_peces);
                    for c=1:2
                        segm(c_frames).id(c_manchas,ind(c))=segm(c_frames).id(c_manchas,ind(c))+.5; % As� quedar� un 1 en los que los dos mapas se pongan de acuerdo, y 0.5 si no se ponen de acuerdo
                    end
                    segm(c_frames).identificado(c_manchas)=true; % Mantengo esto para que funcione el c�digo m�s adelante, pero no se guardar� (porque no guardo segm)
                end % if primera vuelta
                % Ahora mete los resultados en mancha2id.
                if c_vueltas==2 && length(segm(c_frames).identificado)>=c_manchas && segm(c_frames).identificado(c_manchas)
                    ind=find(segm(c_frames).id(c_manchas,:)>0); % Lo suyo ser�a un ==1, pero lo dejo as� de momento por compatibilidad con una versi�n que ten�a un bug y pon�a doses y treses.
                    if length(ind)==1
                        mancha2id(datosegm.archivo2frame(c_archivos,c_frames),c_manchas)=ind;
                    end % if identificaci�n correcta
                    identificados(datosegm.archivo2frame(c_archivos,c_frames),c_manchas)=true;
                end
                %                 end % if mancha buena
                if c_vueltas==2 % Esto no hace falta que se ejecute para cada mancha. Pero no pasa nada, y es m�s f�cil as�.
                    if isfield(segm(c_frames),'menores') && isfield(datosegm,'guarda_menorescell') && datosegm.guarda_menorescell
                        menores_cell{datosegm.archivo2frame(c_archivos,c_frames)}=segm(c_frames).menores;
                    end
                    if isfield(segm(c_frames),'id') && isfield(datosegm,'guarda_menorescell') && datosegm.guarda_menorescell
                        id_cell{datosegm.archivo2frame(c_archivos,c_frames)}=sparse(segm(c_frames).id);
                    end
                end
            end % c_manchas
        end % c_frames
        if c_vueltas==1 && c_mapas>0
            mapas_act=mapas_act(:,:,:,1:c_mapas);
            menores=comparamapas(mapas_act,referencias,indvalidos);
            disp([c_archivos c_mapas])
        end % if primera vuelta
    end % c_vueltas
%     [c_archivos c_mapas]
    if c_mapas>0
        identificaciones.mancha2id=mancha2id;
        identificaciones.identificados=identificados;
        if isfield(datosegm,'guarda_menorescell') && datosegm.guarda_menorescell
            identificaciones.menores_cell=menores_cell;
            identificaciones.id_cell=id_cell;
        else
            identificaciones.menores_cell=[];
            identificaciones.id_cell=[];
        end
        if isfield(datosegm,'encriptar')
            variable=identificaciones;
            save([datosegm.directorio 'mancha2id'],'variable')
        else
            save([datosegm.directorio 'mancha2id'],'mancha2id','menores_cell','id_cell')
        end
        clear identificaciones
    end
    clear segm
    
    if ~isempty(h_panel)
        progreso=max([.01 c_archivos/n_archivos]);
        set(h_panel.waitIdentification,'XData',[0 0 progreso progreso])
        set(h_panel.textowaitIdentification,'String',[num2str(round(progreso*100)) ' %'])
    end
    
end % c_archivos

if ~isempty(h_panel)
    progreso=1;
    set(h_panel.waitIdentification,'XData',[0 0 progreso progreso])
    set(h_panel.textowaitIdentification,'String',[num2str(round(progreso*100)) ' %'])
end
