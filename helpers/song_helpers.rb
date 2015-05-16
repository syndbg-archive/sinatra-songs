module SongHelpers
    def find_songs
      @songs = Song.all
    end

    def find_song
      Song.get(params[:id])
    end

    def create_song
      Song.create(params[:song])
    end
end

helpers SongHelpers
