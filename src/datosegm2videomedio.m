% 24-Dec-2013 17:12:39 Hago que tome obj de datosegm.
% 12-Dec-2013 17:08:18 Hago que use VideoReader cuando la versi�n de Matlab
% es reciente
% 13-Aug-2013 12:06:34 Hago que use datosegm.mascara, en vez de
% recalcularla desde el roi
% 03-Jun-2013 16:47:03 Evito que abra todos los archivos al principio, creando una mega-variable obj.
% 10-Apr-2013 16:56:19 A�ado datosegm.interval
% 27-Feb-2013 20:04:29 Me doy cuenta de que la mediana tarda much�simo m�s que la media, y es lo que m�s est� tardando de la segmentaci�n. As� que pongo otra vez media para la normalizaci�n de intensidades.
% 11-Feb-2013 17:34:26 A�ado videomedio_cuentaframes
% 08-Feb-2013 17:25:07 Mejoro la forma en la que pasa de color a grayscale
% 25-Jan-2013 12:45:00 Hago que funcione con la nueva versi�n de datosegm
% que permite que segm est� troceado diferente que los v�deos
% 27-Nov-2012 19:48:51 A�ado la barra de progreso del panel
% 24-Nov-2012 14:24:49 Hago que pueda funcionar usando la figura del panel
% 12-Nov-2012 17:36:49 Cambio media por mediana para la normalizaci�n de cada frame. Hago que s�lo coja la parte de mascara_intensmed (antes estaba mal)
% 10-Nov-2012 19:09:07 Lo preparo para otras extensiones
% 24-Oct-2012 12:13:45 A�ado cambiacontraste
% 08-May-2012 20:28:17 Corrijo para que no falle cuando hay menos de
% nframes_media
% 25-Jan-2012 19:58:55 Anulo el c�lculo del umbral.
% 25-Jan-2012 19:34:19 A�ado el c�lculo del umbral. Adem�s simplifico la forma
% de elegir los frames, usando equiespaciados.
% APE 22 ago 11

% (C) 2014 Alfonso P�rez Escudero, Gonzalo G. de Polavieja, Consejo Superior de Investigaciones Cient�ficas

% Este programa carga frame a frame en vez de v�deos completos. Esto hace
% que el proceso de carga sea como 4 veces m�s lento, pero tiene la ventaja
% de no necesitar tanta memoria.
%
% handles se refiere a los handles del panel (varible h). Puede simplemente no meterse.

function datosegm=datosegm2videomedio(datosegm,nframes_media,handles)

if nargin<2 || isempty(nframes_media)
    nframes_media=1000;
end

if ~isfield(datosegm,'interval')
    datosegm.interval=[1 size(datosegm.frame2archivo,1)];
end

camposhandles={'ejes','lienzo_manchas','lienzo_mascara','frame','waitBackground','textowaitBackground','Background'};
if nargin<3
    handles=[];
else % Comprueba que todos los handles est�n activos. Si no, los anula por seguridad.
    for c_campos=1:length(camposhandles)
        if ~isfield(handles,camposhandles{c_campos}) || ~ishandle(handles.(camposhandles{c_campos}))
            handles=[];
        end
    end % c_campos
end

if ~isempty(handles)
    title(handles.ejes,'Computing background...')
    set(handles.colorbar,'Visible','off')
    set(handles.lienzo_manchas,'Visible','off')
    set(handles.lienzo_mascara,'Visible','off')
end

n_archivos=size(datosegm.archivovideo2frame,1);
% for c_archivos=1:n_archivos
%     if strcmpi(datosegm.extension,'avi')
%         obj(c_archivos)=mmreader([datosegm.directorio_videos datosegm.raizarchivo_videos num2str(c_archivos) '.avi']);
%     end        
% end % c_archivos

c_frames=0;
n_frames=diff(datosegm.interval)+1;
if nframes_media>n_frames
    nframes_media=n_frames;
end
indices=equiespaciados(nframes_media,n_frames)+datosegm.interval(1)-1;
suma=zeros(datosegm.tam);
videomedio_cuentaframes=suma;
if isfield(datosegm,'mascara_intensmed') && ~isempty(datosegm.mascara_intensmed)
    mascara_intensmed=datosegm.mascara_intensmed;
else
    mascara_intensmed=datosegm.mascara;
end
archivoabierto=0;
for frame_act=indices
    archivo=datosegm.frame2archivovideo(frame_act,1);
    % Comprueba si hay que crear el objeto v�deo de nuevo
    crearobj=true;
    if isfield(datosegm,'obj') && ~isempty(datosegm.obj{archivo})
        try a=get(datosegm.obj{archivo}); crearobj=false; catch; end
    end
    if crearobj
        % Si son demasiados, borra los objetos de datosegm
        if isfield(datosegm,'obj') && sum(cellfun(@(x) ~isempty(x),datosegm.obj))>100
            datosegm.obj=cell(1,size(datosegm.archivo2frame,1));
        end
        if ~isfield(datosegm,'MatlabVersion') || str2double(datosegm.MatlabVersion(1))<8
            if ~isempty(dir([datosegm.directorio_videos datosegm.raizarchivo_videos num2str(archivo) '.' datosegm.extension]))
                datosegm.obj{archivo}=mmreader([datosegm.directorio_videos datosegm.raizarchivo_videos num2str(archivo) '.' datosegm.extension]);
            else
                datosegm.obj{archivo}=mmreader([datosegm.directorio_videos datosegm.raizarchivo_videos '.' datosegm.extension]);
            end
        else
            if ~isempty(dir([datosegm.directorio_videos datosegm.raizarchivo_videos num2str(archivo) '.' datosegm.extension]))
                datosegm.obj{archivo}=VideoReader([datosegm.directorio_videos datosegm.raizarchivo_videos num2str(archivo) '.' datosegm.extension]);
            else
                datosegm.obj{archivo}=VideoReader([datosegm.directorio_videos datosegm.raizarchivo_videos '.' datosegm.extension]);
            end
        end
        archivoabierto=archivo;
    end
    frame_arch=datosegm.frame2archivovideo(frame_act,2);
    frame=read(datosegm.obj{archivo},frame_arch);
    if size(frame,3)==3
        frame(:,:,1)=rgb2gray(frame);
        frame=frame(:,:,1);
    end
    frame_doub=double(frame(:,:,1,1)); % Los dos unos deber�an ser innecesarios
    if datosegm.cambiacontraste
        frame_doub=255-frame_doub;
    end
    frame_doub=frame_doub/mean(frame_doub(mascara_intensmed));
    if all(~isnan(frame_doub(:))) % Porque en algunos v�deos hay alg�n frame raro que es todo negro
        suma = suma + frame_doub;
        videomedio_cuentaframes=videomedio_cuentaframes+(frame_doub<datosegm.umbral);
        c_frames=c_frames+1;
    end
    if mod(c_frames,10)==0
        if ~isempty(handles)
            set(handles.frame,'CData',suma)
            set(handles.waitBackground,'XData',[0 0 c_frames/nframes_media c_frames/nframes_media])
            set(handles.textowaitBackground,'String',[num2str(round(c_frames/nframes_media*100)) ' %'])
            % only draw if the handles are set
            drawnow
        else
            fprintf('%g,',c_frames)
        end
    end
end % frame_act
datosegm.videomedio=suma/c_frames;
datosegm.videomedio_cuentaframes=videomedio_cuentaframes/c_frames;

if ~isempty(handles)
    set(handles.waitBackground,'XData',[0 0 c_frames/nframes_media c_frames/nframes_media])
    set(handles.textowaitBackground,'String',[num2str(round(c_frames/nframes_media*100)) ' %'])
    title(handles.ejes,'')
    set(handles.colorbar,'Visible','on')
    set(handles.lienzo_manchas,'Visible','on')
    set(handles.lienzo_mascara,'Visible','on')
    set(handles.Background,'Value',1)
end
